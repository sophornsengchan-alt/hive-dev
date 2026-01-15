declare module "@salesforce/apex/TaskRelatedController.getOpenTasks" {
  export default function getOpenTasks(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/TaskRelatedController.getCompletedTasks" {
  export default function getCompletedTasks(param: {parentId: any}): Promise<any>;
}
declare module "@salesforce/apex/TaskRelatedController.reAssignTask" {
  export default function reAssignTask(param: {userID: any, taskIds: any}): Promise<any>;
}
declare module "@salesforce/apex/TaskRelatedController.queryRelatedFields" {
  export default function queryRelatedFields(param: {whoIds: any}): Promise<any>;
}
