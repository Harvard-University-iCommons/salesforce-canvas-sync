trigger syncEnrollmentToCanvas on CanvasEnrollment__c (after insert, after update) {
    if(System.isFuture() || System.isBatch()){
        System.debug('we are in future or batch context - stopping');
    } else {
        for (CanvasEnrollment__c e : Trigger.new) {
            if(e.Status__c == 'Deleted') {
                CanvasClient.syncEnrollmentToCanvas(e.Id, 'delete');
            } else if (e.Status__c == 'Active') {
                CanvasClient.syncEnrollmentToCanvas(e.Id, 'add_update');
            } else {
                // TODO: handle Pending/Inactive statuses
            }
        }       
    }
}