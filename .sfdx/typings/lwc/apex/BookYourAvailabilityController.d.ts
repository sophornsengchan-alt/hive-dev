declare module "@salesforce/apex/BookYourAvailabilityController.apexInit" {
  export default function apexInit(): Promise<any>;
}
declare module "@salesforce/apex/BookYourAvailabilityController.getNextPrevWeeklyUserAvailability" {
  export default function getNextPrevWeeklyUserAvailability(param: {curDate: any, mode: any}): Promise<any>;
}
declare module "@salesforce/apex/BookYourAvailabilityController.createUserAvailabilityRecords" {
  export default function createUserAvailabilityRecords(param: {jsonUAW: any}): Promise<any>;
}
