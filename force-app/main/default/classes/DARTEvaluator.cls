/** Convert the keyvalue from dart5 to dart6 form 
LOG:
 - NK:15/07/2013: this temporary fixed the "," in the Audience Segment from Kijiji kv issue
 - methods: functionalizeOnce, parse
 - NK:13/01/2015: added one more operator "Not Equal, <>"
 - NK:24/02/2021:US-0009123.[Ads 2020] Optimize the Targetings Screen - KeyValues section
 @: 18.09.2023 /Vimean Heng/US-0013941 - PART 3 - Upgrade API version of all classes having an API version lower than 31
*/
public without sharing class DARTEvaluator{

    static final String REP_COMMA = '!c!';
    final static String BIGOR = 'BIGOR';
    final static String BIGAND = 'BIGAND';
    final static String BIGOR_TEXT = '- OR -';
    final static String BIGAND_TEXT = '- AND -';

    final static String AUD_SEG = 'Audience Segment';

    final static String regxSet = '(-\\s(\\bOR||\\bAND)\\s-)'; //'(a=b) - AND - (c=d) - OR - (e=f) - AND - (g=h)';


    public static List<List<CustomCriteriaSet>> convertToCritSet(String oldForm5)
    {  
        system.debug('>>>oldForm5: '+oldForm5);
        List<List<CustomCriteriaSet>> toplcTmp = new List<List<CustomCriteriaSet>>();
        
        List<String> listCritSetString = oldForm5.split(regxSet); //spit bigOr and bigAnd
        //system.debug('>>>size: '+listCritSetString.size());
        for(String kvStringPerSet : listCritSetString)
        {
            system.debug('>>>kvStringPerSet: '+kvStringPerSet);
            

            Functionalizer fn = new Functionalizer();
            String formula=fn.functionalize(kvStringPerSet.trim());
            system.debug('>>>formula: '+formula);
            Parser ps = new Parser();
            Node node=ps.parse(formula);
            Evaluator eval = new Evaluator();        
            Node newNode = node.getParent().getLeft();            
            ps.dump(newNode, 1);
            
            List<CustomCriteriaSet> lc = new List<CustomCriteriaSet>();
            eval.evaluate(newNode,lc,null);  
            
            String opperatorSet = 'OR';
            //find operator between Set
            if(listCritSetString.size()>1)
            {
                String tmp = oldForm5.substring(oldForm5.indexOf(kvStringPerSet)+kvStringPerSet.length(),oldForm5.length());
                
                opperatorSet = (tmp.trim().startsWith(BIGOR_TEXT)||String.isBlank(tmp))?'OR':'AND';
                //system.debug('>>>tmp: '+tmp+'>>>>>>>opperatorSet: '+opperatorSet);
            }
            for(CustomCriteriaSet cs: lc)
            {
                cs.operatorSET = opperatorSet;
            }
            //system.debug('>>>lc: '+lc);
            toplcTmp.add(lc);
        }

        // Functionalizer fn = new Functionalizer();
        // String formula=fn.functionalize(oldForm5);
        // Parser ps = new Parser();
        // Node node=ps.parse(formula);

        // system.debug('>>oldForm5: '+oldForm5);
        // system.debug('>>formula: '+formula); 
        
        // Evaluator eval = new Evaluator();        
        // Node newNode = node.getParent().getLeft();
        
        // ps.dump(newNode, 1);
        
        // List<CustomCriteriaSet> lc = new List<CustomCriteriaSet>();
        // List<List<CustomCriteriaSet>> toplc = new List<List<CustomCriteriaSet>>();
        
        // eval.evaluate(newNode,lc, toplc,null);        
 
        // if (toplc.isEmpty()) {
        //     if (!lc.isEmpty()) toplc.add(lc);
        // }
        // List<List<CustomCriteriaSet>> toplcTmp = new List<List<CustomCriteriaSet>>();
        // for (List<CustomCriteriaSet> lcTmp : toplc) {
        //     if (lcTmp.isEmpty()) continue;
        //     toplcTmp.add(lcTmp);
        // }

        return toplcTmp;
    }
         
    public class Condition {
        private Integer level;

        private String parameter;
        private String value;
        private String operator;    //=,<>
        private String operatorVal; //3,key-value within key
        
        public String getParameter() {
            return parameter;
        }
        public void setParameter(String parameter) {
            this.parameter = parameter;
        }
        public String getValue() {
            return value;
        }
        public void setValue(String value) {
            this.value = value;
        }
        public String getOperator() {
            return operator;
        }
        public String getOperatorVal() {
            return operatorVal;
        }
        public void setOperator(String operator) {
            this.operator = operator;
        }
    }
    
    public class CustomCriteriaSet {
        //NK:24/02/2021:US-0009123. add operator to each set
        private String operator_is; //0,IS, IS NOT
        private String operatorSET = 'OR'; //1,set-set: OR/AND
        private String operatorKey; //2,key-key within set 
        
        private Integer level;

        public String getOperatorSET()
        {
            return operatorSET;
        }     
        public String getOperatorKey()
        {
            return operatorKey;
        }  
             
        public String getOperator()
        {
            return operator_is;
        }
        public void setOperator(String op)
        {
            this.operator_is = op;
        }
   
        private List<Condition> criterion = new List<Condition>();
    
        public List<Condition> getCriterion() {
            return criterion;
        }
    
        // public void setCriterion(List<Condition> criterion) {
        //     this.criterion = criterion;
        // }
        
    }

    public class Evaluator {
        public void evaluate(Node node, List<CustomCriteriaSet> lcss, CustomCriteriaSet ccs) {
			
            if (node!=null) {
               // system.debug('>>>>nodeName: '+node.getName()+'  Level: '+node.level);
               if (node.getName().equalsIgnoreCase('EQ')||node.getName().equalsIgnoreCase('NEQ')) {
                   
                   Condition c = new Condition();
                   c.setParameter(node.getLeft().getName());
                   c.setValue(node.getRight().getName());
                   c.setOperator(node.getName().equalsIgnoreCase('EQ')?'=':'<>'); 
                   c.operatorVal = node.getParent().getName()=='root'?'OR':node.getParent().getName();
                   c.level = node.level;

                   //system.debug('>>>>c: '+c);
                //    CustomCriteriaSet ccs2 = null;
                   
                //    if (ccs==null) {//single val in a set?
                //        ccs2 = new CustomCriteriaSet();
                //        ccs = ccs2;
                //        ccs2.operatorKey = node.getParent().getName()=='root'?'OR':node.getParent().getName();
                //        lcss.add(ccs2);		
                //    }
                //    ccs.setOperator(node.getName().equalsIgnoreCase('EQ')?'=':'<>'); 
                //    ccs.getCriterion().add(c);       
                   
                   
                    CustomCriteriaSet ccs1 = ccs;
                    if (ccs1 == null) {
                        ccs1 = new CustomCriteriaSet();                        
                    } 
                    //ccs1.operatorSET = ccs.operatorSET;
                    ccs1.setOperator(node.getName().equalsIgnoreCase('EQ')?'=':'<>'); 
                    ccs1.operatorKey = node.getParent().getName()=='root'?'OR':node.getParent().getName();

                    if(ccs1.getCriterion().isEmpty())
                    {
                        ccs1.getCriterion().add(c);
                    }else {
                        Condition lastCon = ccs1.getCriterion()[ccs1.getCriterion().size()-1];
                        if(lastCon.getParameter() == c.getParameter())
                        {
                            ccs1.getCriterion().add(c);
                        }else {
                            CustomCriteriaSet ccs2 = new CustomCriteriaSet();
                            ccs2.setOperator(node.getName().equalsIgnoreCase('EQ')?'=':'<>'); 
                            ccs2.operatorKey = node.getParent().getName()=='root'?'OR':node.getParent().getName();
                            ccs2.criterion = new List<Condition>{c};                            
                            lcss.add(ccs2); 
                        }
                    }
                    
                    if (node.getParent().getName()=='root')
                    {
                        lcss.add(ccs1); 
                        c.operatorVal = 'OR'; //direct from Set (single val in a set)
                    }
                   
                   
               }
               else if (node.getName().equalsIgnoreCase('OR')) {
                   
                //    CustomCriteriaSet ccs1 = new CustomCriteriaSet();
                //    ccs1.operatorKey = 'OR';
                //     //null if single Set (no bigor, no bigand)
                //     ccs1.operatorSET = ccs==null?'OR':ccs.operatorSET; //bring operator Set to the next crit in the same Set     

                //    evaluate(node.getLeft(), lcss,ccs1) ;
                //    if (ccs1.getCriterion().size()>0)
                //    lcss.add(ccs1);	
                   
                   
                //    CustomCriteriaSet ccs2 = new CustomCriteriaSet();
                //    evaluate(node.getRight(), lcss,ccs2) ;
                //    if (ccs2.getCriterion().size()>0)
                //    lcss.add(ccs2);					
                
                   //---
                   CustomCriteriaSet ccs1 = ccs;
                   if (ccs1==null) {
                       ccs1 = new CustomCriteriaSet();
                       ccs1.level = node.level;
                   } 
                   ccs1.operatorKey = node.getParent().getName()=='root'?'AND':'OR';    //default AND
                   //null if single Set (no bigor, no bigand)
                   ccs1.operatorSET = ccs==null?'OR':ccs.operatorSET; //bring operator Set to the next crit in the same Set   
                   evaluate(node.getLeft(), lcss,ccs1);      
                   evaluate(node.getRight(), lcss,ccs1);     
                   if ((node.getParent().getName()=='root') && ccs1.getCriterion().size()>0)
                   lcss.add(ccs1); 

                   
               }
               else if (node.getName().equalsIgnoreCase('AND')) {
                   
					//    CustomCriteriaSet ccs2 = null;
					//    if (ccs==null) {
					//        ccs2 = new CustomCriteriaSet();
					//        ccs2.operatorKey='AND';
					//        ccs2.operatorSET = ccs==null?'OR':ccs.operatorSET;    //bring operator Set to the next crit in the same Set    
					//        ccs = ccs2;
					//        ccs2.operatorSET = ccs==null?'OR':ccs.operatorSET; //bring operator Set to the next crit in the same Set 
					//        lcss.add(ccs2);		
					//    }
					   
					//    evaluate(node.getLeft(), lcss,ccs);
					//    evaluate(node.getRight(), lcss,ccs) ;

					CustomCriteriaSet ccs1 = new CustomCriteriaSet();
                    ccs1.level = node.level;
					ccs1.operatorSET = ccs==null?'OR':ccs.operatorSET;  
                    ccs1.operatorKey='AND';
					evaluate(node.getLeft(), lcss,ccs1);                  
					if (ccs1.getCriterion().size()>0)
					lcss.add(ccs1); 
							
					CustomCriteriaSet ccs2 = new CustomCriteriaSet();
                    ccs2.level = node.level;
					ccs2.operatorSET = ccs==null?'OR':ccs.operatorSET;  
                    ccs2.operatorKey='AND';
					evaluate(node.getRight(), lcss,ccs2); 
					if (ccs2.getCriterion().size()>0)
					lcss.add(ccs2);     
                   
               }else if (node.getName().equalsIgnoreCase('')) {
                   evaluate(node.getLeft(), lcss,ccs);
                   evaluate(node.getRight(), lcss,ccs);
               }
               
            }
           
       }
       /***NK
        public void evaluate(Node node, List<CustomCriteriaSet> lcss,List<List<CustomCriteriaSet>> toplc, CustomCriteriaSet ccs) {
            if (node!=null) {
                if (node.getName().equalsIgnoreCase('EQ') || 
                    node.getName().equalsIgnoreCase('NEQ')
                        ) {
                            Condition c = new Condition();
                            c.setParameter(node.getLeft().getName());
                            c.setValue(node.getRight().getName());
                            c.setOperator(node.getName().equalsIgnoreCase('EQ')?'=':'<>');  //xxxx 

                            CustomCriteriaSet ccs1 = ccs;
                            if (ccs1 == null) {
                                ccs1 = new CustomCriteriaSet();
                            } 
                            ccs1.getCriterion().add(c);
                            
                            if (node.getParent().getName()=='root' || node.getParent().getName()=='BIGOR')
                            lcss.add(ccs1); 
                                
                            
                        } else if (node.getName().equalsIgnoreCase('OR')) {
                            CustomCriteriaSet ccs1 = ccs;
                            if (ccs1==null) {
                                ccs1 = new CustomCriteriaSet();
                            } 
                            evaluate(node.getLeft(), lcss,toplc,ccs1);      
                            evaluate(node.getRight(), lcss,toplc,ccs1);     
                            if ((node.getParent().getName()=='root' || node.getParent().getName()=='BIGOR') && ccs1.getCriterion().size()>0)
                            lcss.add(ccs1); 

                        } else if (node.getName().equalsIgnoreCase('AND')) {
                            CustomCriteriaSet ccs1 = new CustomCriteriaSet();
                            evaluate(node.getLeft(), lcss,toplc,ccs1);                  
                            if (ccs1.getCriterion().size()>0)
                            lcss.add(ccs1); 
                                    
                            CustomCriteriaSet ccs2 = new CustomCriteriaSet();
                            evaluate(node.getRight(), lcss,toplc,ccs2); 
                            if (ccs2.getCriterion().size()>0)
                            lcss.add(ccs2);     

                        } else if (node.getName().equalsIgnoreCase('BIGOR')) {

                            List<CustomCriteriaSet> lcleft = new List<CustomCriteriaSet>();
                            toplc.add(lcleft);
                            evaluate(node.getLeft(), lcleft,toplc, ccs);                    
                            
                            List<CustomCriteriaSet> lcright = new List<CustomCriteriaSet>();
                            toplc.add(lcright);
                            evaluate(node.getRight(), lcright,toplc,ccs);   

                        } else if (node.getName().equalsIgnoreCase('')) {
                            evaluate(node.getLeft(), lcss,toplc,ccs);
                            evaluate(node.getRight(), lcss,toplc,ccs);
                        }
                    }
        }
        
        */

        /**** SPP ADDED **/
        // public Node deepCopy(Node n) {
        //     Node newNode = new Node(n.Name);
        //     if (n.getLeft() != null) {
        //         newNode.setLeft(deepCopy(n.getLeft()));
        //     }
        //     if (n.getRight() != null) {
        //         newNode.setRight(deepCopy(n.getRight()));
        //     }
        //     return newNode;
        // }
        
        // public  void distribute(Node n){
        //      if (n!=null) {
        //         if (n.getName().equals('AND')) {
        //             //  (a + b) * c -> a*c + b*c
        //             Node left = n.getLeft();
        //             Node right = n.getRight();
                    
        //             if (left.getName().equals('OR') ) {
        //                 Node a = left.getLeft();
        //                 Node b = left.getRight();
        //                 Node c = right;
        //                 Node newparentnode = new Node('OR');
                        
        //                 Node newleftnode = new Node('AND');
        //                 newleftnode.setLeft(a);
        //                 newleftnode.setRight(c);
                        
        //                 Node newrightnode = new Node('AND');
        //                 newrightnode.setLeft(b);
        //                 newrightnode.setRight(deepCopy(c));
                        
        //                 newparentnode.setLeft(newleftnode);
        //                 newparentnode.setRight(newrightnode);
                        
        //                 if (n.getParent()!=null && n.getParent().getLeft()!=null && n.getParent().getLeft()==n) {
        //                     n.getParent().setLeft(newparentnode);
        //                 } else {
        //                     n.getParent().setRight(newparentnode);
        //                 }
                        
        //                 distribute(newparentnode.getLeft());
        //                 distribute(newparentnode.getRight());
        //             } else if (right.getName().equals('OR') ) {
        //                 // a * (b + c) -> a*b + a*c
        //                 Node a = left;
        //                 Node b = right.getLeft();
        //                 Node c = right.getRight();
                        
        //                 Node newparentnode = new Node('OR');
                        
        //                 Node newleftnode = new Node('AND');
        //                 newleftnode.setLeft(a);
        //                 newleftnode.setRight(b);
                        
        //                 Node newrightnode = new Node('AND');
        //                 newrightnode.setLeft(deepCopy(a));
        //                 newrightnode.setRight(c);
                        
        //                 newparentnode.setLeft(newleftnode);
        //                 newparentnode.setRight(newrightnode);
                        
        //                 if (n.getParent()!=null && n.getParent().getLeft()!=null && n.getParent().getLeft()==n) {
        //                     n.getParent().setLeft(newparentnode);
        //                 } else {
        //                     n.getParent().setRight(newparentnode);
        //                 }
        //                 distribute(newparentnode.getLeft());
        //                 distribute(newparentnode.getRight());
        //             }
        //         } else {
        //             distribute(n.getLeft());
        //             distribute(n.getRight());
        //         }
        //      }
        // }
        /**** SPP ADDED **/
    }
    
    public class Functionalizer {
        //private final static String [] KEYS = {' AND ',' OR ', ' LIKE ', '<>','<=', '>=','<','>','=', '*', '+','/','-'};
        // BIG OR
        private final String[] KEYS = new String[]{' BIGAND ',' BIGOR ',' OR ', ' AND ','=','<>'}; //xxxx
        
        private  Map<String,String> KEYS_ALIAS=new Map<String, String>{'='=> 'EQ','<>'=>'NEQ'}; //xxxx
        //static {
            //KEYS_ALIAS.put('<=', 'GTE');
            //KEYS_ALIAS.put('<=', 'LTE');
            //KEYS_ALIAS.put('<', 'LT');
            //KEYS_ALIAS.put('>', 'GT');
            //KEYS_ALIAS.put('>=', 'GTE');
            //KEYS_ALIAS.put('*', 'MULT');
            //KEYS_ALIAS.put('+', 'ADD');
            //KEYS_ALIAS.put('-', 'SUB');
            //KEYS_ALIAS.put('/', 'DIV');
            //KEYS_ALIAS.put('<>', 'OPOSIT');
            //KEYS_ALIAS.put('=', 'EQ');
        //};
            
        public String functionalize(String formula) {
			formula = formula.replaceAll('/\\>\\]/gi,"]"', ']'); //formula.replaceAll("/\\>\\]/gi,']'", "]");
            formula = formula.replaceAll('/\\[\\</gi', '[');    //formula.replaceAll("/\\[\\</gi", "[");
            if(formula.indexOf('"') != -1) formula = formula.replaceAll('"', '\''); //formula = formula.replaceAll("\"", "'");
            if(formula.indexOf('- OR -') != -1) formula = formula.replaceAll('- OR -', BIGOR);    //formula.replaceAll("/\\[\\</gi", "[");
            if(formula.indexOf('- AND -') != -1) formula = formula.replaceAll('- AND -', BIGAND);  //NK:25/02/2021:US-0009123

            for (String key : KEYS) {
                while (true) {
                    String tmp = functionalizeOnce(key, formula);
                    if (tmp.equals(formula)) {
                        break;
                    }
                    formula = tmp;
                }
            }
            //return formula;
            return formula.replaceAll(';', ',');
        }
        
        /*
        private String functionalizeOnce(String key, String formula) {
            String work = hideString(formula);
            Integer operatorPos = work.indexOf(key);
            Integer useless =0;
            if (operatorPos != -1) {
                Integer leftOpPos = getOperator(-1, work, operatorPos);
                String leftOp = (formula.substring(leftOpPos, operatorPos));
                Integer rightOpPos = getOperator(1, work, operatorPos + key.length()) + 1;
                String rightOp = (formula.substring(operatorPos + key.length(),rightOpPos));
                
                if (key.equals('=') && leftOpPos>0) {
                    // remove ( ) useless
                    String s = formula.substring(leftOpPos-1, leftOpPos);
                    String t = formula.substring(rightOpPos,rightOpPos+1);
                    
                    if (s.equals('(') && t.equals(')')) {
                        useless  = 1;
                    }
                }
                
                String funcKey = key.trim();
                String alias = KEYS_ALIAS.get(funcKey);
                if (alias != null) {
                    funcKey = alias;
                }
                return formula.substring(0, leftOpPos - useless) + funcKey + '(' + leftOp
                        + ',' + rightOp + ')' + formula.substring(rightOpPos + useless);
            }
            return formula;
        }*/
        
        // SPP CHANGES
        private  String functionalizeOnce(String key, String formula) {
            formula = formula.replace('\"', '\'');
            String work = hideString(formula);
            Integer operatorPos = work.indexOf(key);
            Integer useless =0;
            if (operatorPos != -1) {
                Integer leftOpPos = getOperator(-1, work, operatorPos, key);
                String leftOp = (formula.substring(leftOpPos, operatorPos));
                Integer rightOpPos = getOperator(1, work, operatorPos + key.length(),key) + 1;
                String rightOp = (formula.substring(operatorPos + key.length(),rightOpPos));
                // spp in case of final operand , with ( or ), we replace to {{ }}
                if (rightOp.indexOf('=')==-1 && rightOp.indexOf('<>')==-1) {
                    rightOp = rightOp.replaceAll('\\(','#Ø');
                    rightOp = rightOp.replaceAll('\\)','#ø');
                }
                
                //NK:15/07/2013: this temporary fixed the "," in the Audience Segment from Kijiji kv issue
                //methods: functionalizeOnce, parse
                if(AUD_SEG.equals(leftOp.trim()) && rightOp.contains(','))
                {
                    rightOp = rightOp.replace(',',REP_COMMA);
                }
                
				String funcKey = key.trim();
				String alias = KEYS_ALIAS.get(funcKey);
				if (alias != null) {
				    funcKey = alias;
				}
                
                if (key.equals('=') && leftOpPos>0) {
                    // remove ( ) useless
                    String s = formula.substring(leftOpPos-1, leftOpPos);
                    String t = formula.substring(rightOpPos,rightOpPos+1);
                    if (s.equals('(') && t.equals(')')) {
                        useless  = 1;
                    }
                }
                
                // case um=10,12,13
                if (key=='=' ) {//&& leftOp!=AUD_SEG
                    String[] operands = rightOp.split(',');
                    if (operands.size()>1) {
                        String newform = '';
                        Integer c = 0;
                        for (Integer i=0;i<operands.size();i++) {
                            newform = newform + funcKey + '(' + leftOp + ';' + operands[i] + ')';
                            c++;
                            if (c==2) {
                                newform = 'OR(' + newform + ')';
                                c=1;
                            }
                            if (i<operands.size()-1) {
                                newform = newform + ';';
                            }
                        }
                        return formula.substring(0, leftOpPos - useless) + newform + formula.substring(rightOpPos + useless);
                    }
                }
                return formula.substring(0, leftOpPos - useless) + funcKey + '(' + leftOp
                        + ';' + rightOp + ')' + formula.substring(rightOpPos + useless);
            }
            return formula;
        }
        // SPP CHANGES: 26/03/2013
        private Integer getOperator(Integer step, String work, Integer startPos, String key) {
			// Bunhor @15-May-18: Adding these codes to fix Apex CPU time limit exceeded
        	if(key=='=') {
        		if(step==1) {
        			return startPos + work.subString(startPos).indexOf(')') - 1;
        		}
        		return work.subString(0, startPos).lastIndexOf('(') + 1;
        	} else if (key==' OR ') {
        		if(step==1) {
        			return startPos + work.subString(startPos).indexOf('))');
        		}
        		String tem = work.subString(0, startPos);
        		return tem.indexOf(';') == -1 ? (tem.lastIndexOf('((') +1) : tem.lastIndexOf('(') ; 
        	}
        	// -----------------
        	
            Integer i = startPos;
            Integer lvl = 0;
            while (true) {
            	String sub1 = work.subString(i,i+1);
                if (sub1 == ';' && lvl == 0) {//work.charAt(i)
                    break;
                } else {
	                if (sub1 == '(') {
	                    lvl += step;
	                } else if (sub1 == ')') {
	                    lvl -= step;
	                }
	                if (lvl == -1) {
	                    break;
	                } else {
		                i += step;
		                if (i < 0 || i >= work.length()) {
		                    break;
		                }
	                }
                }
            }
            return i - step;
        }
 
        private String hideString(String s) {
        	if(!s.contains('\'')) return s;
            boolean inString = false;
            String ret = '';
            for (Integer i = 0; i < s.length(); i++) {
                if (s.subString(i,i+1) == '\'') {
                    inString = !inString;
                }
                ret += inString && s.subString(i,i+1) != '\'' ? ' ' : s.subString(i,i+1);
            }
            return ret;
        }
    }
    
        
    public class Node {
        private Integer level;

        private String name;
        private Node parent;
        
        private Node left;
        private Node right;
        
        public Node getLeft() {
            return left;
        }
    
        public void setLeft(Node left) {
            this.left = left;
            left.parent = this;
        }
    
        public Node getRight() {
            return right;
        }
    
        public void setRight(Node right) {
            this.right = right;
            right.parent = this;
        }
    
        // List<CustomCriteriaSet> crit;
        // public List<CustomCriteriaSet> getCrit() {
        //     return crit;
        // }
    
        // public void setCrit(List<CustomCriteriaSet> crit) {
        //     this.crit = crit;
        // }
    
        public Node(String pName) {
            name = pName.trim();//.replaceAll('/', '');//pName.trim().replaceAll('/'/gi', '');
            name = name.replaceAll('#Ø','(');
            name = name.replaceAll('#ø',')');
        }
        
        public String getName() {
            return name;
        }
        
        public Node getParent() {
            return parent;
        }
    }
    
    public class Parser {
        public void dump(Node node, Integer lvl) {
            if (node!=null) {
            //for (Integer i = 0; i < lvl; i++) {
                //System.debug('-------------->\t');
            //}
            node.level = lvl;
            //System.debug('-------------->(' + node.getName());
                dump(node.getLeft(), lvl+1);
                dump(node.getRight(), lvl+1);
            //for (Integer i = 0; i < lvl; i++) {
                //System.debug('-------------->\t');
            //}
            //System.debug('-------------->)');     
            }
        }
        
        public  boolean insideQuotes(String s, Integer pos) {
			// Bunhor @15-May-18: Adding and commenting codes to fix Apex CPU time limit exceeded
        	String sub = s.subString(0, pos+1); 
        	if(sub.indexOf('\'') == -1) return false;
        	return Math.mod(sub.countMatches('\''), 2) != 0;
        	/**
            boolean insideQuotes = false;
            for (Integer i = 0; i < s.length(); i++) {
                if (s.substring(i,i+1) == '\'') {
                    insideQuotes = !insideQuotes;
                }
                if (i == pos) return insideQuotes;
            }
            return false;
			*/
        }
        
        // SPP ADD
        Set<String> operatorfunc = new Set<String> { BIGAND,BIGOR,'OR','AND', 'EQ', 'NEQ'};

        public  Node parse(String formula) {
            Node rootNode = new Node('root');
            Integer pos = 0;
            String read = '';
            Node tmp;
            Node current = rootNode ;
            while (true) {
                if (formula.substring(pos,pos+1) == '(') {
                    if (read.length() > 0 && operatorfunc.contains(read)) {
                        tmp = new Node(read);
                        if (current.getLeft()!=null) {
                            current.setRight(tmp);
                        }
                        else current.setLeft(tmp);
                        current = tmp;
                        read = '';
                    }
                } else if (formula.substring(pos,pos+1) == ')') {
                    if (read.length() > 0) {
	                   //NK:15/07/2013: this temporary fixed the "," in the Audience Segment from Kijiji kv issue
	                   //methods: functionalizeOnce, parse
	                   if(AUD_SEG.equals(current.getLeft().getName().trim()))
	                   {
	                       read=read.replace(REP_COMMA,',');
	                   }
                       tmp = new Node(read);
                       current.setRight(tmp);
                       read = '';
                    }
                    // the node is full, we can pop
                    if (current.getRight()!=null && current.getLeft()!=null) {
                            current = current.getParent();
                    }
                } else if (formula.substring(pos,pos+1) == ','
                        && insideQuotes(formula, pos) == false) {
                    if (read == ' ') {
                        read = '';
                    } else if (read.length() > 0) {
                        tmp = new Node(read);
                        current.setLeft(tmp);
                        read = '';
                    }
                } else {
                    read += formula.substring(pos,pos+1);
                }
                pos++;
                if (pos >= formula.length())
                    break;
            }
            return rootNode.getLeft();
        }
    }
}