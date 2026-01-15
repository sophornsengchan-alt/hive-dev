// File: GC_SaveLogNormalize.cls
// Implements the Genesys SaveLog extension point.
// - Canonicalizes keys (whoid -> WhoId, activitydate -> ActivityDate, etc.)
// - Normalizes WhoId (e.g., "[{id:003...}]") to a single Id string
// - Parses ActivityDate into a Date (handles "YYYY-M-D" and "YYYY-MM-DD")
// - Coerces CallDurationInSeconds to Integer
// - Trims CallObject to 255 chars
// - Adds robust debug logging and safe DML
global with sharing class GC_SaveLogNormalize implements purecloud.CTIExtension.SaveLog {

    public String onSaveLog(String data) {
        System.debug(LoggingLevel.DEBUG, 'GC_SaveLogNormalize:onSaveLog RAW DATA => ' + data);
        if (String.isBlank(data)) return '';

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(data);
        Map<String, Object> callLog = (payload == null) ? null : (Map<String, Object>) payload.get('callLog');
        if (callLog == null) {
            System.debug(LoggingLevel.WARN, 'GC_SaveLogNormalize: no callLog in payload');
            return '';
        }

        // ---- 0) Canonicalize keys to correct API names (case-insensitive to Genesys payload) ----
        Map<String, String> canon = new Map<String,String>{
            'whoid' => 'WhoId',
            'subject' => 'Subject',
            'status' => 'Status',
            'type' => 'Type',
            'activitydate' => 'ActivityDate',
            'calldurationinseconds' => 'CallDurationInSeconds',
            'callobject' => 'CallObject'
        };
        Map<String, Object> f = new Map<String, Object>();
        for (String k : callLog.keySet()) {
            String keyLower = k != null ? k.toLowerCase() : k;
            String target = canon.containsKey(keyLower) ? canon.get(keyLower) : k; // keep customs as-is
            f.put(target, callLog.get(k));
        }

        System.debug(LoggingLevel.DEBUG, 'GC_SaveLogNormalize: canonicalized payload => ' + JSON.serialize(f));

        // ---- 1) Normalize WhoId ----
        normalizeWhoId(f);

        // ---- 2) Normalize ActivityDate -> Date ----
        normalizeActivityDate(f);

        // ---- 3) Coerce CallDurationInSeconds -> Integer ----
        coerceDuration(f);

        // ---- 4) Trim CallObject to 255 ----
        trimCallObject(f);

        // ---- 5) Ensure minimal required fields for a Task ----
        if (!f.containsKey('Subject') || String.isBlank(String.valueOf(f.get('Subject')))) {
            f.put('Subject', 'GC Normalize (smoke)'); // easy to spot in list views
        }
        if (!f.containsKey('Status')) f.put('Status', 'Completed');
        if (!f.containsKey('Type'))   f.put('Type',   'Call');

        System.debug(LoggingLevel.DEBUG, 'GC_SaveLogNormalize: normalized payload => ' + JSON.serialize(f));

        // ---- 6) Safe DML ----
        try {
            Task t = (Task) JSON.deserialize(JSON.serialize(f), Task.class);
            upsert t;
            System.debug(LoggingLevel.DEBUG, 'GC_SaveLogNormalize: INSERTED Task Id => ' + t.Id);
            return t.Id; // SUCCESS (non-empty string required by Genesys)
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'GC_SaveLogNormalize: DML FAILED => ' + e.getMessage() + ' | ' + e.getStackTraceString());
            return '';   // FAIL per contract
        }
    }

    // ---------- helpers ----------

    private static void normalizeWhoId(Map<String,Object> f) {
        if (!f.containsKey('WhoId')) return;
        String who = extractIdString(f.get('WhoId'));
        if (isSfId(who)) {
            f.put('WhoId', who);
        } else {
            System.debug(LoggingLevel.WARN, 'GC_SaveLogNormalize: dropping malformed WhoId => ' + String.valueOf(f.get('WhoId')));
            f.remove('WhoId'); // avoid MALFORMED_ID hard failure
        }
    }

    private static void normalizeActivityDate(Map<String,Object> f) {
        Date d;
        if (f.containsKey('ActivityDate')) {
            Object v = f.get('ActivityDate');
            if (v instanceof Date) {
                d = (Date)v;
            } else {
                String s = String.valueOf(v);
                Date parsed = parseDateYMD(s);
                d = (parsed != null) ? parsed : Date.today();
            }
        } else {
            d = Date.today();
        }
        f.put('ActivityDate', d);
    }

    private static void coerceDuration(Map<String,Object> f) {
        if (!f.containsKey('CallDurationInSeconds')) return;
        try {
            Integer secs = Integer.valueOf(String.valueOf(f.get('CallDurationInSeconds')));
            if (secs < 0) secs = 0;
            f.put('CallDurationInSeconds', secs);
        } catch (Exception e) {
            f.remove('CallDurationInSeconds');
        }
    }

    private static void trimCallObject(Map<String,Object> f) {
        if (!f.containsKey('CallObject')) return;
        String co = String.valueOf(f.get('CallObject'));
        if (co != null && co.length() > 255) f.put('CallObject', co.substring(0,255));
    }

    private static Boolean isSfId(String s) {
        if (String.isBlank(s)) return false;
        if (s.length() < 15 || s.length() > 18) return false;
        String invalidChars = s.replaceAll('[a-zA-Z0-9]', '');
        return String.isBlank(invalidChars);
    }

    private static String extractIdString(Object raw) {
        if (raw == null) return null;

        if (raw instanceof String) {
            String s = ((String)raw).trim();

            // Matches "[{id:003...}]"
            Pattern p = Pattern.compile('\\[\\{\\s*id\\s*:\\s*([a-zA-Z0-9]{15,18})\\s*\\}\\]');
            Matcher m = p.matcher(s);
            if (m.matches()) return m.group(1);

            // If looks like JSON, try to parse then recurse
            if ((s.startsWith('[') && s.endsWith(']')) || (s.startsWith('{') && s.endsWith('}'))) {
                try {
                    Object parsed = JSON.deserializeUntyped(s);
                    return extractIdString(parsed);
                } catch (Exception ignore) {}
            }
            return s;
        }

        if (raw instanceof List<Object>) {
            List<Object> L = (List<Object>)raw;
            return L.isEmpty() ? null : extractIdString(L[0]);
        }

        if (raw instanceof Map<String, Object>) {
            Map<String, Object> M = (Map<String, Object>)raw;
            if (M.containsKey('id'))    return extractIdString(M.get('id'));
            if (M.containsKey('value')) return extractIdString(M.get('value'));
        }

        return String.valueOf(raw);
    }

    // Parse "YYYY-M-D" or "YYYY-MM-DD" into a Date; return null if it doesn't match
    private static Date parseDateYMD(String s) {
        if (s == null) return null;
        Matcher m = Pattern.compile('^(\\d{4})-(\\d{1,2})-(\\d{1,2})$').matcher(s.trim());
        if (!m.matches()) return null;
        Integer yyyy = Integer.valueOf(m.group(1));
        Integer mm   = Integer.valueOf(m.group(2));
        Integer dd   = Integer.valueOf(m.group(3));
        try {
            return Date.newInstance(yyyy, mm, dd);
        } catch (Exception e) {
            return null;
        }
    }
}