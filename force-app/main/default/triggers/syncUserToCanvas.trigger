trigger syncUserToCanvas on CanvasUser__c (after insert, after update) {
    for (CanvasUser__c u : Trigger.new) {
            if(System.isFuture() || System.isBatch()){
                System.debug('we are in future or batch context - stopping');
            } else {
                CanvasClient.syncCanvasUser(u.ID);  

                 ActivityLog__c log = new  ActivityLog__c();
                log.LEVEL__c = 'AUDIT';
                log.Message__c = 'Sync user to Canvas '+u.Name;
                log.Source__c='Trigger:syncUserToCanvas';
                insert log;              
            }
    }
}