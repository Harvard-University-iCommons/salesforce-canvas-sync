public with sharing class CanvasHelper {
    
    public static void ActivityLogGenerate(String level, String message, String source) {
        ActivityLog__c log = new  ActivityLog__c();
        log.LEVEL__c = level;                          
        log.Message__c = message;
        log.Source__c=source;
        insert log; 
    }
}
