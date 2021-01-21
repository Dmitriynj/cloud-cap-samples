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
   
     function FilterExpr() {
    	let parsedWhereClause = [];
        let concatLevel = 0; // to nested "concat expressions"
 
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
            createConcutArgsStructure
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

FilterExprSequence = (Expr (_ logicalOperator _ Expr)*)

FilterCompletion = (_ logicalOperator _ Expr)*

Expr = (
		(notOperator _)? 
        (
        	"contains" containsFunc / 
        	"endswith" endswithFunc /
            "startswith" startswithFunc /
            GroupedExpr
        )
    ) /
	(
    	"length" lengthExpr /
        "indexof" indexofExpr /
        "substring" substringExpr /
        "tolower" tolowerExpr /
        "toupper" toupperExpr /
        "trim" trimExpr /
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
	= '(' 
    {
    	console.log('opening group');
        filterExpr.appendWhereClause(['(']);
    }  
closeGroup
	= ')' 
    {
    	console.log('closing group');
        filterExpr.appendWhereClause([')']);
    }
    
    

// ---------- Single $filter expression ----------
// ---------- 
compareExpr
	= expr:$(
    	fieldRef _ 
        (
        	(eqOperator _ ((SQUOTE parsedStr SQUOTE) / parsedNumber)) / 
        	(compOperator _ parsedNumber)     	
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
parsedStr 
	= val:strEntireVal 
    { filterExpr.appendWhereClause([val]); }
number "number" 
	= number:$([0-9]+ (('.') [0-9]+)?) 
    { console.log(number,Number(number)); return { val: Number(number) }; }
parsedNumber
	= val:number 
    { filterExpr.appendWhereClause([val]); }
    
    
// ---------- URI syntax [RFC3986] ----------
// ----------
otherDelims   = "!" / "(" / ")" / "*" / "+" / "," / ";"
unreserved = [A-Za-z] / [0-9] / " " / "-" / "." / "_" / "~"
pcharNoSQUOTE = unreserved / otherDelims / "$" / "&" / "=" / ":" / "@"
SQUOTE "quotation mark" = "'"
strEntireVal = val:$(( SQUOTEInString / pcharNoSQUOTE )*)
	{ return { val }; }
string "string literal"
	= val: $(SQUOTE strEntireVal SQUOTE)
    { console.log('val', val) }
SQUOTEInString = SQUOTE SQUOTE // two consecutive single quotes represent one within a string literal

    
// ---------- String functions ----------
// ---------- 
//
// ---------- "contains" ----------
//
containsFunc 
	= $('(' fieldRef ',' SQUOTE containsStrArg SQUOTE ')')
containsStrArg = val:strEntireVal
	{ filterExpr.appendLikeFunc('contains', val); }
//
// ---------- "endswith" ----------
//
endswithFunc 
	= $('(' fieldRef ',' SQUOTE endswithStrArg SQUOTE ')')
endswithStrArg = val:strEntireVal
	{ filterExpr.appendLikeFunc('endswith', val); }
//   
// ---------- "startswith" ----------
//
startswithFunc 
	= $('(' fieldRef ',' SQUOTE startswithStrArg SQUOTE ')')
startswithStrArg = val:strEntireVal
	{ filterExpr.appendLikeFunc('startswith', val); }
//  
// ---------- "length" ----------
//
lengthExpr 
	= $('(' lengthExprField ')'  _ (compOperator / eqOperator) _ parsedNumber)    
lengthExprField = val:field
	{ filterExpr.appendFuncArgs('length', val); }
//    
// ---------- "indexof" ----------
//
indexofExpr 
	= $('(' indexofExprField ',' SQUOTE indexofStrArg SQUOTE ')'  _ (compOperator / eqOperator) _ parsedNumber)   
indexofExprField = val:field
	{ filterExpr.appendFuncArgs('locate', val); }
indexofStrArg = val:strEntireVal
	{ filterExpr.updateLastFuncArgs(val); }
//    
// ---------- "substring" ----------
//
substringExpr 
	= $('(' substringExprField ',' substringIntArg ')' _ eqOperator _ SQUOTE parsedStr SQUOTE)   
substringExprField = val:field
	{ filterExpr.appendFuncArgs('substring', val); }
substringIntArg = numVal:number
	{ let { val } = numVal; filterExpr.updateLastFuncArgs(++val); }
//
// ---------- "tolower" ----------
//
tolowerExpr 
	= $('(' tolowerExprField ')' _ eqOperator _ SQUOTE parsedStr SQUOTE)    
tolowerExprField = val:field
	{ filterExpr.appendFuncArgs('lower', val); }
//
// ---------- "toupper" ----------
//
toupperExpr 
	= $('(' toupperExprField ')' _ eqOperator _ SQUOTE parsedStr SQUOTE)
toupperExprField = val:field
	{ filterExpr.appendFuncArgs('upper', val); }
//   
// ---------- "trim" ----------
//
trimExpr 
	= $('(' trimExprField ')' _ eqOperator _ SQUOTE parsedStr SQUOTE)
trimExprField = val:field
	{ filterExpr.appendFuncArgs('trim', val); }

//   
// ---------- "concat" ----------
//
concatExpr = concatExprPiece _ eqOperator _ SQUOTE parsedStr SQUOTE

concatExprPiece 
	= $(concatName '(' (concatExprPiece / concatExprFieldOne) ',' SQUOTE concatExprStr SQUOTE ')')
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

//-- Whitespaces
_ "one or more whitespaces" = $[ \t\n]+ 
o "optional whitespaces" = $[ \t\n]* 