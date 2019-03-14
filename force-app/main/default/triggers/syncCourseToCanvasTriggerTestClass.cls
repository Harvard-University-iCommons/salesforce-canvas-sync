@isTest
private class syncCourseToCanvasTriggerTestClass {
   static testMethod void myUnitTest() {
      //Create Data for Customer Objet
      CanvasCourse__c  canvasObj = new CanvasCourse__c();
      canvasObj.CanvasCourseId__c = 123;
      canvasObj.CanvasSubAccountId__c = 10;
      canvasObj.Title__c = 'Test Title';
      insert canvasObj;
      
      // Now, our trigger will fire on After update event so update the Records
      // Test.startTest();    // Starts the scope of test
      // //Set mock callout class
      // Test.setMock(HttpCalloutMock.class, new SingleRequestMock());
      // canvasObj.Title__c = 'New Title';
      // update canvasObj;
      // Test.stopTest();     // Ends the scope of test
      
      // Now check if it is giving desired results using system.assert
      CanvasCourse__c c = [SELECT Id, Name, Title__c, CanvasCourseId__c, Start_Date__c,
       End_Date__c, CanvasSubAccountId__c, BlueprintCanvasCourseId__c
        FROM CanvasCourse__c WHERE CanvasCourseId__c = :canvasObj.CanvasCourseId__c LIMIT 1];        
        
      system.assertEquals(c.Title__c,'New Title');
   }
}