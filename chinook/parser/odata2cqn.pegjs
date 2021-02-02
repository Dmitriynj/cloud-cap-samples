/**
 * Odata Spec http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/abnf/odata-abnf-construction-rules.txt
 * Future test cases http://docs.oasis-open.org/odata/odata/v4.0/errata03/os/complete/abnf/odata-abnf-testcases.xml
 *
 * Limitations: 
 * - Type, Geo functions are not supported,
 * maxdatetime, mindatetime, fractionalseconds,
 * totaloffsetminutes, date, totalseconds,
 * floor, ceiling also are not supported by CAP
 * - Lambda expressions are not supported by nodejs runtime
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
	let orderby = [];
	let filterExpr;
	let expadRefsStack = [];
    
    const select = (col) => {
    	if (!SELECT.columns) { 
			SELECT.columns = columns;
		}
    	columns.push(col);
    }
    const expand = (ref) => {
        select(ref);
        stack.push(columns);
		columns = ref.expand = [];
		expadRefsStack.push(ref); 
   	}
    const end = () => { 
		columns = stack.pop();
		expadRefsStack.pop();
	}
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
	= (p:field { SELECT.from = p }) ( o"?"o QueryOptions )? 
    {return { SELECT }}

QueryOptions = (
	"$expand=" expand /
	"$select=" select /

    ("$top=" val:top { (SELECT.limit || (SELECT.limit={})).rows = val; }) /
    ("$skip=" val:skip { (SELECT.limit || (SELECT.limit={})).offset = val; }) /
    ("$count=" val:count { SELECT.count = val; }) /
    ("$orderby=" val:orderby { SELECT.orderBy = val; }) /
    
	(("$filter=" {
        console.log('starting $filter');
    	filterExpr = new FilterExpr();    
	}) FilterExprSequence  {
    	console.log('end of $filter');
    	SELECT.where = filterExpr.getParsedWhereClause();
	})
)( o'&'o QueryOptions )?


// ---------- Grouped $filter expression ----------
// ----------

FilterExprSequence = (Expr (SP logicalOperator SP Expr)*)
GroupedExpr = (startGroup FilterExprSequence closeGroup) 
Expr = (
		(notOperator SP)?  ( boolFunc / GroupedExpr )
    ) / ( commonExp )
startGroup 
	= OPEN
    { filterExpr.appendWhereClause(['(']); }  
closeGroup
	= CLOSE 
    { filterExpr.appendWhereClause([')']); } 


// ---------- Function expressions ----------
// ---------- 
commonExp = val:(
		timeExpr /
		secondExpr /
		minuteExpr /
		hourExpr /
		dayExpr /
		monthExpr /
		yearExpr /
		compStrExpr /
		compareNumExpr
	)
 	{	  
      	const res = val.filter(cur => cur !== ' ');
		filterExpr.appendWhereClause([...res]);
	}

compStrExpr 
	= firstArgObj:strArg
	  SP operatorVal:eqOperator SP 
	  secondArgObj:strArg
compareNumExpr 
	= firstArgObj:numberArg
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArgObj:numberArg
dayExpr 
	= firstArg:(dayFunc / dayVal)
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:(dayFunc / dayVal)
hourExpr 
	= firstArg:(hourFunc / hourVal) 
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:(hourFunc / hourVal)
minuteExpr
	= firstArg:( minuteFunc / minuteVal )
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:( minuteFunc / minuteVal )
monthExpr
	= firstArg:(monthFunc / monthVal)
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:(monthFunc / monthVal)
secondExpr
	= firstArg:(secondFunc / secondVal)
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:(secondFunc / secondVal)
yearExpr
	= firstArg:(yearFunc / yearVal)
	  SP operatorVal:( eqOperator / numCompOperator ) SP 
	  secondArg:(yearFunc / yearVal)
timeExpr 
	= firstArg:(timeFunc / timeOfDayValue)
	  SP operatorVal:( numCompOperator / eqOperator ) SP 
	  secondArg:(timeFunc / timeOfDayValue)
     
strArg = (
	substringFunc / 
	tolowerFunc /
	toupperFunc /
	trimFunc /
	concatFunc /
	strLiteral /
	field
)     
numberArg = (
	lengthFunc /
	indexofFunc /
	roundFunc /
	number /
	field
)

// ---------- Functions ----------
// 
// ---------- "contains" / "endswith" / "startswith" ----------
boolFunc 
	= funcName:( "contains" / "endswith" / "startswith" )
	  OPEN
	  	fieldRef:strArg COMMA 
		containsStrArg:strArg
	  CLOSE 
	  {
		function getLikeArgs (value) {
          	const funcArgs = {
			  contains: [ "'%'", value, "'%'" ],
			  endswith: [ "'%'", value ],
			  startswith: [ value, "'%'" ]
		  	};
          	return funcArgs[funcName];
        };
		filterExpr.appendWhereClause([
			fieldRef,
         	'like',
    		{ 
            	func: 'concat', 
               	args: getLikeArgs(containsStrArg)
            },
            'escape',
    		"'^'"
		]);
	  }  
// ---------- "length" ----------
lengthFunc 
	= "length"
	  OPEN
	  	fieldRef:strArg 
	  CLOSE
	  {
		return {
      		func: 'length',
      		args: [ fieldRef ]    
		} 
	  }
// ---------- "indexof" ----------
indexofFunc 
	= "indexof"
	  OPEN
	  	fieldRef:strArg COMMA
		strArgVal:strArg
	  CLOSE
	  {
		return {
      		func: 'locate',
      		args: [ fieldRef, strArgVal ]    
		}
	  }
// ---------- "substring" ----------
substringFunc 
	= "substring"
	  OPEN
	  	fieldRef:strArg COMMA
		arg:( 
			(numberArg COMMA numberArg) /
			numberArg 
		)	
	  CLOSE
       {
		const args = Array.isArray(arg) ?   
				[
					fieldRef, 
					...arg.filter(cur => cur !== ',')
				] :
				[fieldRef, arg];
		return {
      		func: 'substring',
			args: args
		}
	  }
// ---------- "tolower" ----------
tolowerFunc 
	= "tolower"
	  OPEN
	  	fieldRef:strArg
	  CLOSE
	  {
		return {
      		func: 'lower',
      		args: [ fieldRef ]    
		}
	  }
// ---------- "toupper" ----------
toupperFunc 
	= "toupper" 
	  OPEN
	  	fieldRef:strArg 
	  CLOSE
	  {
		return {
      		func: 'upper',
      		args: [ fieldRef ]    
		}
	  }
// ---------- "trim" ----------
trimFunc 
	= "trim"
	  OPEN
	  	fieldRef:strArg
	  CLOSE
	  {
		return {
      		func: 'trim',
      		args: [ fieldRef ]    
		}
	  }
// ---------- "concat" ----------
concatFunc 
	= "concat"
	  OPEN	
	  	fieldRef:strArg COMMA
		strArgVal:strArg
	  CLOSE
	  {
		return {
      		func: 'concat',
      		args: [ fieldRef, strArgVal ]    
		}
	  }
// ---------- "day" ----------
dayFunc 
	= "day"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / dateValue / field)
 	  CLOSE
	  {
		return {
      		func: 'dayofmonth',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "hour" ----------
hourFunc 
	= "hour"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / timeOfDayValue / field)
 	  CLOSE
	  {
		return {
      		func: 'hour',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "minute" ----------
minuteFunc 
	= "minute"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / timeOfDayValue / field)
 	  CLOSE
	  {
		return {
      		func: 'minute',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "month" ----------
monthFunc 
	= "month"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / dateValue / field)
 	  CLOSE
	  {
		return {
      		func: 'month',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "second" ----------
secondFunc 
	= "second"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / timeOfDayValue / field)
 	  CLOSE
	  {
		return {
      		func: 'second',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "year" ----------
yearFunc 
	= "year"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / dateValue / field)
 	  CLOSE
	  {
		return {
      		func: 'year',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "time" ----------
timeFunc 
	= "time"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / field)
 	  CLOSE
	  {
		return {
			func: 'to_time',
      		args: [ fieldRef ]    
		}
	  }

// ---------- "round" ----------
roundFunc 
	= "round"
	  OPEN
 		fieldRef:(dateTimeOffsetValue / field)
 	  CLOSE
	  {
		  return {
			func: 'round',
      		args: [ fieldRef ]    
		}
	  }


expandQueryOptions = (
	("$expand=" expand) /
	"$select=" select /

    ("$top=" val:top {
		const appendingRef = expadRefsStack[expadRefsStack.length-1];
		(appendingRef.limit || (appendingRef.limit={})).rows = val; 
	}) /
    ("$skip=" val:skip { 
		const appendingRef = expadRefsStack[expadRefsStack.length-1];
		(appendingRef.limit || (appendingRef.limit={})).offset = val;
	}) /
    ("$count=" val:count {
		const appendingRef = expadRefsStack[expadRefsStack.length-1];
		appendingRef.count = val; 
	}) /
    ("$orderby=" val:orderby { 
		const appendingRef = expadRefsStack[expadRefsStack.length-1];
		appendingRef.orderBy = val;
	}) /	
    (("$filter=" {
    	console.log('starting $filter');
    	filterExpr = new FilterExpr();    
	}) FilterExprSequence  {
		console.log('end of $filter');
		const appendingRef = expadRefsStack[expadRefsStack.length-1];
		appendingRef.where = filterExpr.getParsedWhereClause(); 
	})
)( SEMI expandQueryOptions )?

expandPiece = (curRef:field { expand(curRef); }) 
		(OPEN expandQueryOptions CLOSE)? { end(); }
expand
	= expandPiece (o','o expand)?

// field ref
field "field name" 
	= field:$([a-zA-Z] [_a-zA-Z0-9]*) 
    { return { ref: [field] }; }

select 
	= (c:field {select(c)}) 
      (o','o select)?
    
top = n:$DIGIT+
    { return { val: parseInt(n) }; }
  
skip = n:$DIGIT+
    { return { val: parseInt(n) }; }  

count = c:booleanValue
	{ return c === 'true'; }
    
orderbyPiece = val:(field SP ("asc" / "desc"))
	{ 
		const resArray = val.filter(cur => cur !== ' ');
		const cqnToAppend = { ref: [resArray[0].ref[0]], sort: resArray[1] };
		orderby.push(cqnToAppend);
	}
orderby = val:(orderbyPiece (COMMA orderbyPiece)*)
	{ const result = orderby; orderby = []; return result; } 

other "other query options"
	= o:$([^=]+) "=" x:todo
	{ SELECT[o.slice(1)] = x; console.log('another option was called') }
todo = $[^,?&]+


// Primitive literals	
//
// date
dateValue "Edm.Date" = val:$( year "-" month "-" day )
	{ return { val } }
year  = "-"? ( "0" DIGIT DIGIT DIGIT / oneToNine DIGIT DIGIT DIGIT )
yearVal = val:$year { return { val } }
month = "0" oneToNine
      / "1" ( "0" / "1" / "2" )
monthVal = val:$month { return { val } }
day   = "0" oneToNine
      / ( "1" / "2" ) DIGIT
      / "3" ( "0" / "1" )
dayVal = val:$day { return { val } }
oneToNine = "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9"    

// datetime offset
dateTimeOffsetValue "Edm.DateTimeOffset" = val:$( year "-" month "-" day "T" hour ":" minute ( ":" second ( "." fractionalSeconds )? )? ( "Z" / SIGN hour ":" minute ))
	{ return { val: (new Date(val)).toISOString() } }
hour  = ( "0" / "1" ) DIGIT
       / "2" ( "0" / "1" / "2" / "3" ) 
hourVal = val:$hour { return { val } }
minute = zeroToFiftyNine
minuteVal = val:$minute { return { val } }
second = zeroToFiftyNine 
secondVal = val:$second { return { val: parseInt(val).toFixed(3) } }
zeroToFiftyNine = ( "0" / "1" / "2" / "3" / "4" / "5" ) DIGIT
fractionalSeconds = DIGIT DIGIT? DIGIT? DIGIT?
					DIGIT? DIGIT? DIGIT? DIGIT?
                    DIGIT? DIGIT? DIGIT? DIGIT?

// time of day value
timeOfDayValue "Edm.TimeOfDay" = val:$( hour ":" minute ( ":" second ( "." fractionalSeconds )? )? )
	{ return { val } }

// string
strLiteral "Edm.String" = SQUOTE strArgVal:strEntry SQUOTE
	{ return strArgVal; }
strEntry = symbols:( ( SQUOTEInString / pcharNoSQUOTE )* )
	{ return { val: symbols.join('') }; }

// number
number = val:$(
			doubleValue /
			singleValue /	
			decimalValue /
			int64Value /	
			int32Value /
			int16Value
		) { 
        	console.log('number', val)
			return { val: Number(val) }; 
		}

// IEEE 754 binary64 floating-point number (15-17 decimal digits)
doubleValue "Edm.Double" = decimalValue ( "e" SIGN? DIGIT+ )? / nanInfinity 
decimalValue "Edm.Decimal" = SIGN? DIGIT+ ("." DIGIT+)?
// IEEE 754 binary32 floating-point number (6-9 decimal digits)
singleValue "Edm.Single" = doubleValue 
// numbers in the range from -9223372036854775808 to 9223372036854775807        
// contains 1-19 digits
int64Value "Edm.Int64" = SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT? 
				   DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? 
				   DIGIT? DIGIT? DIGIT? DIGIT? DIGIT? 
				   DIGIT? DIGIT? DIGIT? DIGIT? 
// numbers in the range from -2147483648 to 2147483647
// contains 1-15 digits
int32Value "Emd.Int32"
	= val:(SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT?
			DIGIT? DIGIT? DIGIT? DIGIT? DIGIT?
            DIGIT? DIGIT? DIGIT? DIGIT? DIGIT?)
	{ return parseInt(val); }
// numbers in the range from -32768 to 32767 
// contains 1-5 digits
int16Value "Edm.Int16" = SIGN? DIGIT DIGIT? DIGIT? DIGIT? DIGIT?
nanInfinity = 'NaN' / '-INF' / 'INF'
booleanValue = "true" / "false"


// ---------- URI sintax ----------
//
otherDelims   = "!" / "(" / ")" / "*" / "+" / "," / ";"
unreserved = [A-Za-z] / [0-9] / " " / "-" / "." / "_" / "~"
pcharNoSQUOTE = val:$(unreserved / otherDelims / "$" / "&" / "=" / ":" / "@")
				{ return val; }
SQUOTEInString = SQUOTE SQUOTE // two consecutive single quotes represent one within a string literal
				 { return "'"; } // convert double quotation mark to single like in current CAP implementaion 
 
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

// ---------- Operators ----------
//
eqOperator 
	= operatorVal:("eq" / "ne") 
    { return compOperators[operatorVal]; } 
numCompOperator 
	= operatorVal:("lt" / "gt" / "le" / "ge") 
	{ return compOperators[operatorVal]; }	
logicalOperator = operator:$("and" / "or") 
	{ filterExpr.appendWhereClause([operator]); }
notOperator 
	= notOperator:$("not") 
    { filterExpr.appendWhereClause([notOperator]); }


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