trigger syncEnrollmentToCanvas on CanvasEnrollment__c (after insert, after update) {
    for (CanvasEnrollment__c e : Trigger.new) {
            if(System.isFuture() || System.isBatch()){
                System.debug('we are in future or batch context - stopping');
            } else {
                CanvasClient.syncEnrollmentToCanvas(e.Id);               
            }
    }
}