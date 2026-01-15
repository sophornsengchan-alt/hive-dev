declare module "@salesforce/apex/ManageUserController.getContacts" {
  export default function getContacts(): Promise<any>;
}
declare module "@salesforce/apex/ManageUserController.apexSubmitContact" {
  export default function apexSubmitContact(param: {cont: any, listAccIds: any}): Promise<any>;
}
declare module "@salesforce/apex/ManageUserController.apexSubmitUser" {
  export default function apexSubmitUser(param: {contMap: any, listAccContId: any}): Promise<any>;
}
declare module "@salesforce/apex/ManageUserController.apexRemoveContact" {
  export default function apexRemoveContact(param: {targetObject: any, contId: any, usrId: any}): Promise<any>;
}
