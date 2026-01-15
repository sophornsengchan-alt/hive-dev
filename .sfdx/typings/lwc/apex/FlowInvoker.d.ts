declare module "@salesforce/apex/FlowInvoker.invoke" {
  export default function invoke(param: {flowApiName: any, inputVariables: any}): Promise<any>;
}
