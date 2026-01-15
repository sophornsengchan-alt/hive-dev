declare module "@salesforce/apex/menusManagerController.getMenus" {
  export default function getMenus(): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.deleteMenu" {
  export default function deleteMenu(param: {menuId: any}): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.getMenu" {
  export default function getMenu(param: {menuId: any, language: any, spMainDomain: any, revRollUp: any}): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.deleteMenuItem" {
  export default function deleteMenuItem(param: {menuItemId: any}): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.getLanguages" {
  export default function getLanguages(): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.getSPMainDomains" {
  export default function getSPMainDomains(): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.getRevRollUp" {
  export default function getRevRollUp(): Promise<any>;
}
declare module "@salesforce/apex/menusManagerController.importMenu" {
  export default function importMenu(param: {menuJSON: any}): Promise<any>;
}
