# Canvas Sync SFDX App

This Salesforce app contains functionality to help manage courses, users and enrollments in Canvas.

## Installation

After installing this package in your Salesforce org, set up the custom settings: Canvas URL, sub-account ID, and API token. 

## Resources

* sObjects:
    * `CanvasUser__c`: represents a user account in Canvas
    * `CanvasCourse__c`: represents a Canvas course
    * `CanvasEnrollment__c`: represents an enrollment in a Canvas course; links CanvasUser__c and CanvasCourse__c
* Triggers: 
    * `syncUserToCanvas`
    * `syncCourseToCanvas`
    * `syncEnrollmentToCanvas`
* Apex classes:
    * `CanvasClient`: provides some methods that are called by


