/*********************************************************************************************************************************
@ Class:          EBH_CheckRecursive
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Helper Class for Triggers to check recurssion
                  EPH- : Generic class for recursive check.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2017 / JOY MONDOL / Created the class.
*********************************************************************************************************************************/

public Class EBH_CheckRecursive{
    
    public static boolean Run = True;   //Run state
    
    /*****************************************************************************************************************************
    @ Method:         runOnce
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        check run state
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if run once else false 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / JOY MONDOL / Created the  Method.
    *****************************************************************************************************************************/  
    public static boolean runOnce() {
        
        if(Run) {
             
             Run = False;
             return true;
        } else {
            
            return Run;
        }
    }
}