trigger syncEnrollmentToCanvas on CanvasEnrollment__c (after insert, after update) {
    for (CanvasEnrollment__c e : Trigger.new) {
            if(System.isFuture() || System.isBatch()){
                System.debug('we are in future or batch context - stopping');
            } else {
                CanvasClient.syncEnrollmentToCanvas(e.Id);   

                ActivityLog__c log = new  ActivityLog__c();
                log.LEVEL__c = 'AUDIT';
                log.Message__c = 'Added enrollment to Canvas '+e.Name;
                log.Source__c='Trigger:syncEnrollmentToCanvas';
                insert log;            
            }
    }
}