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
        
        return {
        	appendWhereClause,
            getParsedWhereClause,
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
        compareStrExpr /
		compareNumExpr
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
compareStrExpr 
	= fieldRef:field SP
	  operatorVal:eqOperator SP
	  strVal:strLiteral 
	{ 
		filterExpr.appendWhereClause([
			fieldRef, operatorVal, strVal
		])
	}
compareNumExpr 
	= fieldRef:field SP
	  operatorVal:( eqOperator / numCompOperator ) SP
	  numVal:number 
	{ 
		filterExpr.appendWhereClause([
			fieldRef, operatorVal, numVal
		])
	}
field "field name" 
	= field:$([a-zA-Z] [_a-zA-Z0-9]*) 
    { return { ref: [field] }; }
eqOperator 
	= operatorVal:("eq" / "ne") 
    { return compOperators[operatorVal]; } 
numCompOperator 
	= operatorVal:("lt" / "gt" / "le" / "ge") 
	{ return compOperators[operatorVal]; }	
strEntry = val:$( ( SQUOTEInString / pcharNoSQUOTE )* )
	{ return { val }; }
number "number" 
	= number:$([0-9]+ (('.') [0-9]+)?) 
    { return { val: Number(number) }; }


    

// ---------- Function expressions ----------
// ---------- 
strFuncCall = strFuncObj:(
				substringFunc / 
			  	tolowerFunc /
			  	toupperFunc /
			  	trimFunc /
				concatFunc
			  )
			  { 
				console.log('strFuncObj',strFuncObj); 
			  	return strFuncObj;
			  }

strLiteral = SQUOTE strArgVal:strEntry SQUOTE
	{ return strArgVal; }
	
fieldArg = fieldRef:( strLiteral / field )
		   { return fieldRef }



//
// ---------- "contains" ----------
//
containsFunc 
	= "contains" 
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg ) COMMA 
		SQUOTE containsStrArg:strEntry SQUOTE 
	  CLOSE 
	{  
    	filterExpr.appendWhereClause([
			fieldRef,
         	'like',
    		{ 
            	func: 'concat', 
               	args:  [ "'%'", containsStrArg, "'%'"]
            },
            'escape',
    		"'^'"
		]);
    }
//
// ---------- "endswith" ----------
//
endswithFunc 
	= "endswith" 
	  OPEN 
	  	fieldRef:( strFuncCall / fieldArg ) COMMA 
	  	SQUOTE endswithStrArg:strEntry SQUOTE
	  CLOSE
	{ 
		filterExpr.appendWhereClause([    
			fieldRef,
         	'like',
    		{ 
            	func: 'concat', 
               	args:  [ "'%'", endswithStrArg]
            },
            'escape',
    		"'^'"
		]);
	}
//   
// ---------- "startswith" ----------
//
startswithFunc 
	= "startswith" 
	  OPEN 
	  	fieldRef:( strFuncCall / fieldArg ) COMMA
		SQUOTE startswithStrArg:strEntry SQUOTE
	  CLOSE 
	{ 
		filterExpr.appendWhereClause([    
			fieldRef,
         	'like',
    		{ 
            	func: 'concat', 
               	args:  [ startswithStrArg, "'%'" ]
            },
            'escape',
    		"'^'"
		]);
	}
//  
// ---------- "length" ----------
//
lengthExpr 
	= "length"
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg ) 
	  CLOSE  
	  SP operatorVal:(numCompOperator / eqOperator) SP
	  numVal:number     
	{
		filterExpr.appendWhereClause([
			{
      			func: 'length',
      			args: [ fieldRef ]    
			},
			operatorVal,
			numVal,
		]);
	}
//    
// ---------- "indexof" ----------
//
indexofExpr 
	= "indexof"
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg ) COMMA
		SQUOTE strArgVal:strEntry SQUOTE
	  CLOSE 
	  SP operatorVal:(numCompOperator / eqOperator) SP 
	  numVal:number  
	  {
		let { val } = numVal;
		filterExpr.appendWhereClause([
			{
      			func: 'locate',
      			args: [ fieldRef, strArgVal ]    
			},
			operatorVal,
			{ val: ++val },
		]);
	  } 
//    
// ---------- "substring" ----------
// need second call variant
substringFunc 
    = "substring"
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg ) COMMA
		numVal:number
	  CLOSE
	  { 
		let { val } = numVal;
		return {
      		func: 'substring',
      		args: [ fieldRef, {val: ++val} ]    
		}
	  }
substringExpr
	= substrObj:strFuncCall
	  SP operatorVal:eqOperator SP 
	  SQUOTE strArgVal:strEntry SQUOTE
	  {
		filterExpr.appendWhereClause([
			substrObj,
			operatorVal,
			strArgVal,
		]);
	  }
//
// ---------- "tolower" ----------
//
tolowerFunc 
	= "tolower"
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg )
	  CLOSE
	  {
		return {
      		func: 'lower',
      		args: [ fieldRef ]    
		}
	  }
tolowerExpr 
	= tolowerObj:strFuncCall
	  SP operatorVal:eqOperator SP 
	  SQUOTE strArgVal:strEntry SQUOTE 
	  {
		filterExpr.appendWhereClause([
			tolowerObj,
			operatorVal,
			strArgVal,
		]);
	  }
//
// ---------- "toupper" ----------
//
toupperFunc 
	= "toupper" 
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg ) 
	  CLOSE
	  {
		return {
      		func: 'upper',
      		args: [ fieldRef ]    
		}
	  }
toupperExpr 
	= toupperObj:strFuncCall
	  SP operatorVal:eqOperator SP 
	  SQUOTE strArgVal:strEntry SQUOTE
	  {
		filterExpr.appendWhereClause([
			toupperObj,
			operatorVal,
			strArgVal,
		]);
	  }
//   
// ---------- "trim" ----------
//
trimFunc 
	= "trim"
	  OPEN
	  	fieldRef:( strFuncCall / fieldArg )
	  CLOSE
	  {
		return {
      		func: 'trim',
      		args: [ fieldRef ]    
		}
	  }
trimExpr
	= trimObj:strFuncCall
	  SP operatorVal:eqOperator SP 
	  SQUOTE strArgVal:strEntry SQUOTE
	  {
		filterExpr.appendWhereClause([
			trimObj,
			operatorVal,
			strArgVal,
		]);
	  }

//   
// ---------- "concat" ----------
//
concatFunc 
	= "concat"
	  OPEN	
	  	fieldRef:( strFuncCall / fieldArg ) COMMA
		SQUOTE strArgVal:strEntry SQUOTE
	  CLOSE
	  {
		return {
      		func: 'concat',
      		args: [ fieldRef, strArgVal ]    
		}
	  }
concatExpr
	= concatObj:strFuncCall
	  SP operatorVal:eqOperator SP 
	  SQUOTE strArgVal:strEntry SQUOTE
	  {
		filterExpr.appendWhereClause([
			concatObj,
			operatorVal,
			strArgVal,
		]);
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
o "optional whitespaces" = $[ \t\n]* 