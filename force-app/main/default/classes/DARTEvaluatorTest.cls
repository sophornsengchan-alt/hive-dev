@isTest
private class DARTEvaluatorTest {
     
    @IsTest
    static void testEval(){
        
        String oldForm5A ='((Audience Segment=aa1,bbb,ccc) OR (Audience Segment=aa2)) - AND - (((cat<>550) OR (cat<>2984)) AND (fbi<>5500))';
        String oldForm5B ='(fbi=5500)';
        String oldForm5C ='((Audience Segment=aa1) OR (Audience Segment=aa2)) - OR - (((cat<>550) OR (cat<>2984)) AND ((tcat<>20081) OR (tcat<>293)))';
        String oldForm5D  ='( um=10,12,13 )';
        String strangeForm  ='( um=\'test\' )';
       
        Test.startTest();
            List<List<DARTEvaluator.CustomCriteriaSet>> cslist1All = DARTEvaluator.convertToCritSet(oldForm5A);
            List<List<DARTEvaluator.CustomCriteriaSet>> cslist2All = DARTEvaluator.convertToCritSet(oldForm5B);
            List<List<DARTEvaluator.CustomCriteriaSet>> cslist3All = DARTEvaluator.convertToCritSet(oldForm5C);
            List<List<DARTEvaluator.CustomCriteriaSet>> cslist4All = DARTEvaluator.convertToCritSet(oldForm5D);

            DARTEvaluator.convertToCritSet(strangeForm);

            for(List<DARTEvaluator.CustomCriteriaSet> cslist1: cslist1All )
            {    
                for(DARTEvaluator.CustomCriteriaSet set1 : cslist1)
                {
                    set1.getOperatorKey();
                    set1.getOperatorSET();
                    set1.getOperator();
                    for(DARTEvaluator.Condition c: set1.getCriterion())
                    {
                        c.getOperator();
                        c.getOperatorVal();
                        c.getParameter();
                        c.getValue();
                    }
                    
                }    
            }

        Test.stopTest();
        
    }
}