declare module "@salesforce/apex/Deal_DailyViewController.apexInitDailyView" {
  export default function apexInitDailyView(): Promise<any>;
}
declare module "@salesforce/apex/Deal_DailyViewController.apexQueryDailyView" {
  export default function apexQueryDailyView(param: {dealSite: any, dealFormat: any, selVerticals: any, dateYYYMMDD: any, onlyFreeSlot: any}): Promise<any>;
}
declare module "@salesforce/apex/Deal_DailyViewController.apexQueryWeeklyDeals" {
  export default function apexQueryWeeklyDeals(param: {dateYYYMMDD: any, siteId: any, spotLights: any}): Promise<any>;
}
