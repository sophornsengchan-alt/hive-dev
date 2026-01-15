global class CreateUsersAfterRefresh implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        System.debug('Hello Tester Pester ' + context.organizationId() + ' ' + context.sandboxId() + context.sandboxName());
                     

Map<String,id> mapProfiles = new Map<string,id>();
        for (Profile p :[select id,name from profile]){
            mapProfiles.put(p.name,p.id);
        }
        List<User> listOfUsers = new List<User>();
        listOfUsers.add (new User(firstname='Vadhanak',lastname='Voun',email='vadhanak.voun@gaea-sys.com',username='vadhanak.voun@hive.project.com.'+context.sandboxName(),profileId=mapProfiles.get('System Administrator'),Alias='vvoun',TimeZoneSidKey='Europe/Berlin',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',LanguageLocaleKey='en_US'));
        listOfUsers.add (new User(firstname='Standard',lastname='User',email='liny.seoung@gaea-sys.com',username='standard.user@hive.project.com.'+context.sandboxName(),profileId=mapProfiles.get('Standard User Profile'),Alias='standus',TimeZoneSidKey='Europe/Berlin',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',LanguageLocaleKey='en_US'));
        listOfUsers.add (new User(firstname='Marketing',lastname='User',email='liny.seoung@gaea-sys.com',username='marketing.user@hive.project.com.'+context.sandboxName(),profileId=mapProfiles.get('Marketing Profile'),Alias='markuser',TimeZoneSidKey='Europe/Berlin',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',LanguageLocaleKey='en_US'));
        listOfUsers.add (new User(firstname='Business',lastname='Admin',email='liny.seoung@gaea-sys.com',username='business.admin@hive.project.com.'+context.sandboxName(),profileId=mapProfiles.get('Business Admin'),Alias='badmin',TimeZoneSidKey='Europe/Berlin',LocaleSidKey='en_US',EmailEncodingKey='ISO-8859-1',LanguageLocaleKey='en_US'));
     
        //insert listOfUsers;
        
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerUserEmail = true;
        
        Database.insert(listOfUsers,dlo); 
    
    }

    
    

}