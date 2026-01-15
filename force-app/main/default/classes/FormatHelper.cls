/**
* SPP :
*
* This class is a Helper Class 
* 
* Used to format number based on user country
* 
* String s = FormatHelper .format(123456768);
* 
*  If user country = de
* 
* s = 12.345.678,00
* 
* if user country = en
*
* s= 12,345,678.00
* 
*/

public class FormatHelper {

    // this map is used to locate the decimal separator based on the country
    static Map<String,String> localseparator = new Map<String,String>();
    static {
    localseparator.put('en',',.');
    localseparator.put('de','.,');
    }
    
        
            /**
            *
       * This method is used to format decimal value based separator
         *
         */
        
         public static String format(Decimal val, String osep, String nsep)
        {
    
            if(val == null){val = 0;}
            String s, tmp; Integer i = 6;
            s = val.setScale(2).toPlainString().replace(osep, nsep);
            
            while(s.length() > i)
            {
                tmp = s.substring(0, s.length() - i) + osep + s.substring(s.length() - i);
                s = tmp;
                i += 4;
            }
            return s;
        }
        
         public static String format(Decimal formatVal) 
        {
             return format(formatVal,UserInfo.getLocale());
        }
        
        public static String format(Decimal formatVal, String locale)
        {
         String sep = localseparator.get(locale.substring(0,2));
        
         if (sep!=null) {
        
         return format(formatVal,sep.substring(0,1),sep.substring(1,2));
        
         }
        
         // default in case not found
         return format(formatVal,',','.');
        }
        
        
        /**
        *
        * Date Format Helper
        */
        
        
        static String DATE_US1 = 'MM/dd/yyyy';
        static String DATE_US2 = 'MM/dd/yy';
        
        
        /**
        *
        * Format Datetime to business format
        */
        
        public static String formatDT(Datetime dt) {
            
            return formatDT(dt,null);
        }
        
        
        public static String formatDT(Datetime dt, String pattern1) {
            
            if (dt!=null) {
                
                if (String.isEmpty(pattern1)) {
                    return dt.format(DATE_US1);
                }
                return dt.format(pattern1);
                
            }
            
            return '';
        }
        
    }