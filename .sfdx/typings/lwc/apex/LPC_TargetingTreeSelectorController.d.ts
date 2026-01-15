declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.loadSummary" {
  export default function loadSummary(param: {lineItemId: any, contentFile: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.getTree" {
  export default function getTree(param: {treeType: any, lineItemId: any, contentFile: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.getTreeTemplate" {
  export default function getTreeTemplate(param: {treeType: any, targetId: any, lineItemId: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.getChildren" {
  export default function getChildren(param: {treeType: any, parentId: any, level: any, mapDevSelectedMode: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.doSearchTree" {
  export default function doSearchTree(param: {treeType: any, textSearch: any, lineItemId: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.doSaveRecords" {
  export default function doSaveRecords(param: {treeType: any, lineItemId: any, lstTobeSaved: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.saveTemplate" {
  export default function saveTemplate(param: {targetId: any, assoToSave: any}): Promise<any>;
}
declare module "@salesforce/apex/LPC_TargetingTreeSelectorController.doSaveRecordsTempleate" {
  export default function doSaveRecordsTempleate(param: {treeType: any, targetId: any, lstTobeSaved: any}): Promise<any>;
}
