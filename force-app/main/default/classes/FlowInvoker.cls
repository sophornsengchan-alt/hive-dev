public with sharing class FlowInvoker {

    @AuraEnabled
    public static void invoke(String flowApiName, List<Map<String, Object>> inputVariables) {
        if (String.isBlank(flowApiName)) {
            System.debug(LoggingLevel.WARN, 'FlowInvoker: flowApiName is blank. Skipping invocation.');
            return;
        }

        System.debug(LoggingLevel.INFO, 'FlowInvoker: Invoking Flow - ' + flowApiName);
        System.debug(LoggingLevel.INFO, 'FlowInvoker: Input Variables: ' + JSON.serializePretty(inputVariables));

        Map<String, Object> inputMap = new Map<String, Object>();

        for (Map<String, Object> var : inputVariables) {
            try {
                String name = (String) var.get('name');
                Object value = var.get('value');
                inputMap.put(name, value);
                System.debug(LoggingLevel.FINE, 'Input: ' + name + ' = ' + JSON.serialize(value));
            } catch (Exception ex) {
                System.debug(LoggingLevel.WARN, 'FlowInvoker: Skipped malformed input variable. Error: ' + ex.getMessage());
            }
        }

        try {
            Flow.Interview flowInstance = Flow.Interview.createInterview(flowApiName, inputMap);
            flowInstance.start();
            System.debug(LoggingLevel.INFO, 'FlowInvoker: Flow [' + flowApiName + '] invoked successfully.');
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'FlowInvoker: Error invoking flow [' + flowApiName + '].');
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + ex.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'Message: ' + ex.getMessage());
        }
    }
}



/* public with sharing class FlowInvoker {

    @AuraEnabled
    public static void invoke(String flowApiName, List<Map<String, Object>> inputVariables) {
        if (String.isBlank(flowApiName)) {
            System.debug('FlowInvoker: flowApiName is blank, skipping invocation.');
            return;
        }

        System.debug('FlowInvoker: Attempting to invoke flow: ' + flowApiName);
        System.debug('FlowInvoker: Input Variables: ' + inputVariables);

        Map<String, Object> inputMap = new Map<String, Object>();
        for (Map<String, Object> var : inputVariables) {
            try {
                String name = (String) var.get('name');
                Object value = var.get('value');
                System.debug('FlowInvoker: Processing input - ' + name + ' => ' + value);
                inputMap.put(name, value);
            } catch (Exception ex) {
                System.debug('FlowInvoker: Error processing input variable - ' + ex.getMessage());
            }
        }

        try {
            Flow.Interview flowInstance = Flow.Interview.createInterview(flowApiName, inputMap);
            flowInstance.start();
            System.debug('FlowInvoker: Flow invoked successfully.');
        } catch (Exception ex) {
            System.debug('FlowInvoker: Error invoking flow - ' + ex.getMessage());
        }
    }
}

=========================

 public with sharing class FlowInvoker {

    @AuraEnabled
    public static void invoke(String flowApiName, List<Map<String, Object>> inputVariables) {
        // Validate flow name
        if (String.isBlank(flowApiName)) {
            System.debug('FlowInvoker: flowApiName is blank, skipping invocation.');
            return;
        }

        // Convert inputVariables to Flow.Interview input structure
        Map<String, Object> inputMap = new Map<String, Object>();
        for (Map<String, Object> var : inputVariables) {
            String name = (String) var.get('name');
            Object value = var.get('value');
            inputMap.put(name, value);
        }

        // Start the autolaunched flow
        Flow.Interview flowInstance = Flow.Interview.createInterview(flowApiName, inputMap);
        flowInstance.start();
    }
} */