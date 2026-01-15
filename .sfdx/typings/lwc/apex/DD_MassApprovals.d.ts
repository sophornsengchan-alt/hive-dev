declare module "@salesforce/apex/DD_MassApprovals.initData" {
  export default function initData(param: {objectName: any, recordType: any, fieldSetName: any, sortField: any, isAsc: any, search: any}): Promise<any>;
}
declare module "@salesforce/apex/DD_MassApprovals.approveRecords" {
  export default function approveRecords(param: {jsonitems: any, objectName: any}): Promise<any>;
}
declare module "@salesforce/apex/DD_MassApprovals.rejectRecords" {
  export default function rejectRecords(param: {jsonitems: any, objectName: any}): Promise<any>;
}
declare module "@salesforce/apex/DD_MassApprovals.fetchRecordType" {
  export default function fetchRecordType(): Promise<any>;
}
