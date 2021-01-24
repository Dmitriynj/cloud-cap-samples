/**
 * Odata Spec http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/abnf/odata-abnf-construction-rules.txt
 * Future test cases http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/abnf/odata-abnf-testcases.xml
 *
 * Examples: 
 * Books
 * Books/201
 * Books?$select=ID,title&$expand=author($select=name)&$filter=stock gt 1&$orderby=title
 */
{
    const $=Object.assign
    const SELECT={};
    const stack=[];
    let columns=[];
    let filterExpr;
    
    const select = (col) => {
    	if (!SELECT.columns) SELECT.columns = columns
    	columns.push(col)
    }
    const expand = (col) => {
        select (col)
        stack.push (columns)
        columns = col.expand = []
   	}
    const end = ()=> columns = stack.pop()
    const compOperators = {
    	eq: '=',
    	ne: '!=',
    	lt: '<',
    	gt: '>',
    	le: '<=',
    	ge: '>=',
    }
    let funcAppendLink;
    let funcCallRes = [];
   
     function FilterExpr() {
    	let parsedWhereClause = [];
        let concatLevel = 0; // to nested "concat expressions"
        let innerFuncAppendLink;

        function appendWhereClause(body) {
    		if(!parsedWhereClause) {
        		parsedWhereClause = body;
        	} else {
        		parsedWhereClause = [...parsedWhereClause, ...body];
        	}
    	}
        function getParsedWhereClause() {
        	return parsedWhereClause; 
        }
        
        function appendLikeFunc(funcName, val) {
        	const argsOptions = {
            	contains: [ "'%'", val, "'%'"],
                startswith: [ val, "'%'"],
                endswith: [ "'%'", val ]
            }
            const args = argsOptions[funcName];
            
        	appendWhereClause([ 
         		'like',
    			{ 
            		func: 'concat', 
                	args
            	},
            	'escape',
    			"'^'"
    		]);
        }
       
        function appendFuncArgs(funcName, refObj) {
        	appendWhereClause([{
      			func: funcName,
      			args: [ refObj ]    
    		}]);
        }
        
        function updateLastFuncArgs(val) {
        	const funcObj = parsedWhereClause.pop();
        	parsedWhereClause = [...parsedWhereClause, {...funcObj, args: [...funcObj.args, val]}]
        }
        
        function createConcutArgsStructure(refObj) {  
        	function createArgs(curLevel) { 
            	return curLevel === 1 ? [{
          			func: 'concat',
                    args: [ refObj ] 
        		}] : [{
          			func: 'concat',
                    args: [ ...createArgs(curLevel-1) ] 
        		}]
            }

            console.log('concatNestingLevel', concatLevel);
        	if(concatLevel === 1) {
                parsedWhereClause = [...parsedWhereClause, {
      				func: 'concut',
      				args: [ refObj ]    
    			}];
        	} else {
            	parsedWhereClause = [...parsedWhereClause, ...createArgs(concatLevel)]; 
            } 
        }
        function incrementConcutLevel() {
        	concatLevel++;
        }
        function decrementConcutLevel() {
        	concatLevel--;
        }
        
        return {
        	appendWhereClause,
            getParsedWhereClause,
           
            // for "contains" / "endswith" / "startswith" functions
            appendLikeFunc,
            
            // for "length" / "indexof" / "tolower" / "toupper" / "trim" functions
            appendFuncArgs,
            
            // for "indexof" / "substring" functions
            updateLastFuncArgs,
            
            // for "concut" func only
            incrementConcutLevel,
            decrementConcutLevel,
            createConcutArgsStructure,

            innerFuncAppendLink
        }
    }	
}

start = ODataRelativeURI

ODataRelativeURI // Note: case-sensitive!
	= (p:ref { SELECT.from = p }) ( o"?"o QueryOptions )? 
    {return { SELECT }}

QueryOptions = (
	"$expand=" expand /
	"$select=" select /
	"$top="    top /
	"$skip="   skip /
    "$count="  count /
    "$orderby=" orderby /
    (("$filter=" {
    	console.log('starting $filter');
    	filterExpr = new FilterExpr();    
    })  FilterExprSequence {
    	console.log('end of $filter');
    	SELECT.where = filterExpr.getParsedWhereClause();
    })
)( o'&'o QueryOptions )?


// ---------- Grouped $filter expression ----------
// ----------

FilterExprSequence = (Expr (SP logicalOperator SP Expr)*)

FilterCompletion = (SP logicalOperator SP Expr)*

Expr = (
		(notOperator SP)? 
        (
        	containsFunc / 
        	endswithFunc /
            startswithFunc /
            GroupedExpr
        )
    ) /
	(
    	lengthExpr /
        indexofExpr /
        substringExpr /
        tolowerExpr /
        toupperExpr /
        trimExpr /
        concatExpr /
        compareExpr
    )

GroupedExpr = (startGroup FilterExprSequence closeGroup) 
logicalOperator = operator:$("and" / "or") 
	{
    	console.log('logic operator:', operator);
        filterExpr.appendWhereClause([operator]);
    }
notOperator 
	= notOperator:$("not") 
    {
    	console.log('not operator:', notOperator);
        filterExpr.appendWhereClause([notOperator]);
    }
startGroup 
	= OPEN
    {
    	console.log('opening group');
        filterExpr.appendWhereClause(['(']);
    }  
closeGroup
	= CLOSE 
    {
    	console.log('closing group');
        filterExpr.appendWhereClause([')']);
    } 
    

// ---------- Single $filter expression ----------
// ---------- 
compareExpr
	= expr:$(
    	fieldRef SP 
        (
        	(eqOperator SP ((SQUOTE parsedStr SQUOTE) / parsedNumber)) / 
        	(compOperator SP parsedNumber)     	
      	)
      )  
fieldRef = f:field 
	{ filterExpr.appendWhereClause([f]); }
field "field name" 
	= field:$([a-zA-Z] [_a-zA-Z0-9]*) 
    { return { ref: [field] }; }
eqOperator 
	= eqOperator:("eq" / "ne") 
    { filterExpr.appendWhereClause([compOperators[eqOperator]]); } 
compOperator 
	= compOperator:("lt" / "gt" / "le" / "ge") 
    { filterExpr.appendWhereClause([compOperators[compOperator]]); }	
strEntireVal = val:$(( SQUOTEInString / pcharNoSQUOTE )*)
	{ return { val }; }
parsedStr 
	= val:strEntireVal 
    { filterExpr.appendWhereClause([val]); }
number "number" 
	= number:$([0-9]+ (('.') [0-9]+)?) 
    { console.log(number,Number(number)); return { val: Number(number) }; }
parsedNumber
	= val:number 
    { filterExpr.appendWhereClause([val]); }

    
// ---------- String functions ----------
// ---------- 
//
// ---------- "contains" ----------
//
containsFunc 
	= $( "contains" OPEN ( stringFuncCall / fieldRef ) COMMA SQUOTE containsStrArg SQUOTE CLOSE )
	{ console.log('funcCallRes', funcCallRes) }
containsStrArg = val:strEntireVal
	{  
    	filterExpr.appendLikeFunc('contains', val);
		const curWhereClause = filterExpr.getParsedWhereClause();
		filterExpr.innerFuncAppendLink = curWhereClause[curWhereClause.length-3]
											.args[1];
		console.log('innerFuncAppendLink', filterExpr.innerFuncAppendLink);
    }
//
// ---------- "endswith" ----------
//
endswithFunc 
	= $( "endswith" OPEN fieldRef COMMA SQUOTE endswithStrArg SQUOTE CLOSE)
endswithStrArg = val:strEntireVal
	{ filterExpr.appendLikeFunc('endswith', val); }
//   
// ---------- "startswith" ----------
//
startswithFunc 
	= $( "startswith" OPEN fieldRef COMMA SQUOTE startswithStrArg SQUOTE CLOSE )
startswithStrArg = val:strEntireVal
	{ filterExpr.appendLikeFunc('startswith', val); }
//  
// ---------- "length" ----------
//
lengthExpr 
	= $( "length" OPEN lengthExprField CLOSE  SP (compOperator / eqOperator) SP parsedNumber )    
lengthExprField = val:field
	{ filterExpr.appendFuncArgs('length', val); }
//    
// ---------- "indexof" ----------
//
indexofExpr 
	= $( "indexof" OPEN indexofExprField COMMA SQUOTE indexofStrArg SQUOTE CLOSE  SP (compOperator / eqOperator) SP indexofIntArg )   
indexofExprField = val:field
	{ filterExpr.appendFuncArgs('locate', val); }
indexofStrArg = val:strEntireVal
	{ filterExpr.updateLastFuncArgs(val); }
indexofIntArg = numVal:number
	{ let { val } = numVal; filterExpr.appendWhereClause([{val: ++val}]); }
//    
// ---------- "substring" ----------
//
substringFunc = "substring" OPEN substringExprField COMMA substringIntArg CLOSE
substringExpr 
	= $( substringFunc SP eqOperator SP SQUOTE parsedStr SQUOTE )   
substringExprField = val:field
	{ filterExpr.appendFuncArgs('substring', val); }
substringIntArg = numVal:number
	{ let { val } = numVal; filterExpr.updateLastFuncArgs({val: ++val}); }
//
// ---------- "tolower" ----------
//
tolowerFunc = "tolower" OPEN tolowerExprField CLOSE
tolowerExpr 
	= $( tolowerFunc SP eqOperator SP SQUOTE parsedStr SQUOTE )    
tolowerExprField = val:field
	{ filterExpr.appendFuncArgs('lower', val); }
//
// ---------- "toupper" ----------
//
toupperFunc = "toupper" OPEN toupperExprField CLOSE
toupperExpr 
	= $( toupperFunc SP eqOperator SP SQUOTE parsedStr SQUOTE )
toupperExprField = val:field
	{ filterExpr.appendFuncArgs('upper', val); }
//   
// ---------- "trim" ----------
//
trimFunc = "trim" OPEN trimExprField CLOSE
trimExpr 
	= $( trimFunc SP eqOperator SP SQUOTE parsedStr SQUOTE )
trimExprField = val:field
	{ filterExpr.appendFuncArgs('trim', val); }

//   
// ---------- "concat" ----------
//
// concatFunc = 
concatExpr = "concat" concatExprPiece SP eqOperator SP SQUOTE parsedStr SQUOTE

concatExprPiece 
	= $(concatName OPEN (concatExprPiece / concatExprFieldOne) COMMA SQUOTE concatExprStr SQUOTE CLOSE)
	{ filterExpr.decrementConcutLevel(); }
concatName = "concat" 
	{ filterExpr.incrementConcutLevel(); }
concatExprFieldOne = val:field
	{ 
    	console.log('concat field:', val); 
        filterExpr.createConcutArgsStructure(val);
    }
concatExprStr = val:strEntireVal
	{ 
    	console.log('concat str:', val);
    }


// ------ Function expressions -------
//
stringFuncCall = val:(
                    tolowerFunc / 
                    substringFunc /
                    toupperFunc /
                    trimFunc 
)
                {
					// filterExpr.innerFuncAppendLink
                    console.log('filterExpr.innerFuncAppendLink', filterExpr.innerFuncAppendLink)
                }
                    //concatFunc 


            



expand
	= ((c:ref {expand(c)}) (o'('o QueryOptions o')'o)? {end()})
	  (o','o expand)?

select 
	= (c:ref {select(c)}) 
      (o','o select)?
    
top
	= n:$[0-9]+
    { (SELECT.limit || (SELECT.limit={})).rows = { val: parseInt(n) } }
  
skip
	= n:$[0-9]+
    { (SELECT.limit || (SELECT.limit={})).offset = { val: parseInt(n) } }  

other "other query options"
	= o:$([^=]+) "=" x:todo
	{ SELECT[o.slice(1)] = x; console.log('another option was called') }

ref "a reference"
	= p:$[^,?&()]+ { 
    	const reffs = p.split('/');
        if(reffs.length === 2 && reffs[reffs.length-1] === '$count') {
			SELECT.count = true;
		}
        return { ref: [reffs[0]] };
    }

todo = $[^,?&]+

count = c:$[^,?&()]+
	{ if(c === 'true') SELECT.count = true }
    
orderby = o:$[^,?&()]+
	{
    	const matches = o.match(/\w+\s(asc|desc)/g);
    	if(!!matches) {
        	const out = matches[0].split(/\s/g);
    		SELECT.orderby = [
            	{ ref: [out[0]], sort: out[1] }
            ]
        }
    }

//
// ---------- URI sintax ----------
//
otherDelims   = "!" / "(" / ")" / "*" / "+" / "," / ";"
unreserved = [A-Za-z] / [0-9] / " " / "-" / "." / "_" / "~"
pcharNoSQUOTE = unreserved / otherDelims / "$" / "&" / "=" / ":" / "@"
SQUOTEInString = SQUOTE SQUOTE // two consecutive single quotes represent one within a string literal


//   
// ---------- Punctuation ----------
//

WS "whitespace" = ( SP / HTAB )*  

AT     = "@" 
COLON  = ":" 
COMMA  = "," 
EQ     = "="
SIGN   = "+" / "-"
SEMI   = ";" 
STAR   = "*" 
SQUOTE = "'"
OPEN  = "(" 
CLOSE = ")" 


//   
// ---------- ABNF core definitions ----------
//

ALPHA "letter" = [A-Za-z] 
AtoF "A to F" = "A" / "B" / "C" / "D" / "E" / "F" 
DIGIT "digit" = [0-9] 
HEXDIG "hexing" = DIGIT / AtoF 
DQUOTE "double quote" = '"'
SP "space" = ' ' 
HTAB "horizontal tab" = '	' 
WSP "white space" = SP / HTAB 
BIT = "0" / "1" 
RWS = ( SP / HTAB )+  // "required" whitespace 


//-- Whitespaces
_ "one or more whitespaces" = $[ \t\n]+ 
o "optional whitespaces" = $[ \t\n]* 