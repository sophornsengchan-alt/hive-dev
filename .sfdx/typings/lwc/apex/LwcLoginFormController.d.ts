declare module "@salesforce/apex/LwcLoginFormController.doLogin" {
  export default function doLogin(param: {username: any, password: any, lang: any, starturllogin: any}): Promise<any>;
}
declare module "@salesforce/apex/LwcLoginFormController.translateLoginFailedErrorMessage" {
  export default function translateLoginFailedErrorMessage(param: {errMsg: any, lang: any}): Promise<any>;
}
declare module "@salesforce/apex/LwcLoginFormController.fectchUrl" {
  export default function fectchUrl(): Promise<any>;
}
declare module "@salesforce/apex/LwcLoginFormController.fetchLoginLabelTranslation" {
  export default function fetchLoginLabelTranslation(param: {lstLabels: any}): Promise<any>;
}
declare module "@salesforce/apex/LwcLoginFormController.getApexLog" {
  export default function getApexLog(param: {uniqueId: any}): Promise<any>;
}
