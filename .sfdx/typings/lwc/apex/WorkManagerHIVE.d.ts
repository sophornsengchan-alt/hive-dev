declare module "@salesforce/apex/WorkManagerHIVE.workManagerInit" {
  export default function workManagerInit(): Promise<any>;
}
declare module "@salesforce/apex/WorkManagerHIVE.getRecordsPanel" {
  export default function getRecordsPanel(param: {jsonPageInfo: any, jsonPanel: any, sprintId: any}): Promise<any>;
}
declare module "@salesforce/apex/WorkManagerHIVE.wmMoveStory" {
  export default function wmMoveStory(param: {action: any, toSprintId: any, listIds: any}): Promise<any>;
}
declare module "@salesforce/apex/WorkManagerHIVE.wmSaveSetting" {
  export default function wmSaveSetting(param: {jsonString: any}): Promise<any>;
}
