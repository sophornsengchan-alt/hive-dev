/** 
 * Lightning response object
 */
public without sharing class RemoteResponse {
    // Error codes  
    public static final integer STATUSCODE_OK = 0;
    public static final integer STATUSCODE_ERROR = 1;
    public static final integer STATUSCODE_WARNING = 2;
    public static final integer STATUSCODE_FATAL = 3;
    public static final integer STATUSCODE_CUSTOM = 100;
    
    @AuraEnabled
    public integer statusCode = STATUSCODE_OK; // ==> 0 = ok, 1 = ERROR, 2 = succes, but... (with warning message)
    @AuraEnabled
    public String message = ''; // message for display to user
    @AuraEnabled
    public String validationMsg = ''; // message for display to user
    @AuraEnabled
    public String debug = '';
    @AuraEnabled
    public Object content;
    @AuraEnabled 
    public List<Object> contents;
     
    public RemoteResponse() { 
        content = 0; 
        message = 'Default message';
        validationMsg = '';
        contents = new List<Object>(); 
    }
    
    public RemoteResponse (String msg, integer status, Object content) {
        this(msg, status);
        this.content = content;
    }
    
    public RemoteResponse (String msg, integer status) {
        this.message = msg;
        this.statusCode = status; 
        this.validationMsg = '';
    }
    
    public RemoteResponse (Object content) {
        this.setContent(content);
    }
    
    public void setContent(Object content) {
    	this.content = content;
    }
}