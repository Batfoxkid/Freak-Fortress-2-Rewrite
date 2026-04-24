#pragma semicolon 1
#pragma newdecls required

#define FORUMLA_PHRASER	2

typedef ConfigMapMathVarFunc   = function void(const char[] var_name, int var_name_len, float &f, any data);

enum {
	TokenInvalid,
	TokenVar, TokenNum,
	
	/// builtin functions.
	TokenSin, TokenCos, TokenTan,
	TokenArcSin, TokenArcCos, TokenArcTan,
	TokenLog,
	TokenFloor, TokenRound, TokenCeil, TokenFraction,
	TokenToRad, TokenToDegree, TokenRandom, TokenRandomI,
	
	/// builtin constants.
	TokenE, TokenPi, TokenURand,
	
	TokenLParen, TokenRParen,
	TokenLBrack, TokenRBrack,
	TokenPlus, TokenSub,
	TokenMul, TokenDiv,
	TokenPow,
};

enum {
	LEXEME_SIZE=64,
	dot_flag = 1,
};

enum struct Token {
	char  lexeme[LEXEME_SIZE];
	int   size;
	int   tag;
	float val;
}

enum struct LexState {
	Token tok;
	int   i;
}


/** CfgMath by Nergal.
Expression Grammar (hint PEMDAS):
```ebnf
Expr        = AddExpr .
AddExpr     = MulExpr *( ('+' | '-') MulExpr ) .
MulExpr     = PowExpr *( ('*' | '/') PowExpr ) .
PowExpr     = PrefixExpr *( '^' PrefixExpr ) .
PrefixExpr  = *( '-' | '+' ) PostFixExpr .
PostfixExpr = *( ident ( '(' | '[' )? PowExpr , PrefixExpr ) | Factor .
Factor      = number | ident | 'e' (Euler's constant) | 'pi' | 'urand' | '(' Expr ')' | '[' Expr ']' .
```
 */

/// Expr = AddExpr .
stock float ParseExpr(const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	LexState ls; GetToken(ls, expression);
	return ParseAddExpr(ls, expression, fn_math, data);
}

/// AddExpr = MulExpr *( ('+' | '-') MulExpr ) .
static stock float ParseAddExpr(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	float val = ParseMulExpr(ls, expression, fn_math, data);
	if( ls.tok.tag==TokenPlus || ls.tok.tag==TokenSub ) {
		while( ls.tok.tag==TokenPlus || ls.tok.tag==TokenSub ) {
			int t = ls.tok.tag;
			GetToken(ls, expression);
			switch( t ) {
				case TokenPlus: {
					val += ParseMulExpr(ls, expression, fn_math, data);
				}
				case TokenSub: {
					val -= ParseMulExpr(ls, expression, fn_math, data);
				}
			}
		}
	}
	return val;
}

/// MulExpr = PowExpr *( ('*' | '/') PowExpr ) .
static stock float ParseMulExpr(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	float val = ParsePowExpr(ls, expression, fn_math, data);
	if( ls.tok.tag==TokenMul || ls.tok.tag==TokenDiv ) {
		while( ls.tok.tag==TokenMul || ls.tok.tag==TokenDiv ) {
			int t = ls.tok.tag;
			GetToken(ls, expression);
			switch( t ) {
				case TokenMul: {
					val *= ParsePowExpr(ls, expression, fn_math, data);
				}
				case TokenDiv: {
					val /= ParsePowExpr(ls, expression, fn_math, data);
				}
			}
		}
	}
	return val;
}

/// PowExpr = PrefixExpr *( '^' PrefixExpr ) .
static stock float ParsePowExpr(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	float val = ParseFnExpr(ls, expression, fn_math, data);
	if( ls.tok.tag==TokenPow ) {
		while( ls.tok.tag==TokenPow ) {
			GetToken(ls, expression);
			val = Pow(val, ParseFnExpr(ls, expression, fn_math, data));
		}
	}
	return val;
}

/// PrefixExpr = *( '-' | '+' ) Factor .
static stock float ParsePrefixExpr(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	if( ls.tok.tag==TokenSub ) {
		GetToken(ls, expression);
		return -ParsePrefixExpr(ls, expression, fn_math, data);
	} else if( ls.tok.tag==TokenPlus ) {
		GetToken(ls, expression);
		return FloatAbs(ParsePrefixExpr(ls, expression, fn_math, data));
	}
	return ParseFactor(ls, expression, fn_math, data);
}

/// PostfixExpr = *( ident ) ( '(' | '[' )? _ , PowExpr | PrefixExpr .
static stock float ParseFnExpr(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	switch( ls.tok.tag ) {
		case TokenSin: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return Sine(val);
		}
		case TokenArcSin: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return ArcSine(val);
		}
		case TokenCos: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return Cosine(val);
		}
		case TokenArcCos: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return ArcCosine(val);
		}
		case TokenTan: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return Tangent(val);
		}
		case TokenArcTan: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return ArcTangent(val);
		}
		case TokenLog: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return Logarithm(val);
		}
		case TokenFloor: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return RoundToFloor(val) + 0.0;
		}
		case TokenRound: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return RoundFloat(val) + 0.0;
		}
		case TokenCeil: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return RoundToCeil(val) + 0.0;
		}
		case TokenFraction: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return FloatFraction(val);
		}
		case TokenToRad: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return DegToRad(val);
		}
		case TokenToDegree: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return RadToDeg(val);
		}
		case TokenRandom: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return GetRandomFloat(0.0, val);
		}
		case TokenRandomI: {
			GetToken(ls, expression);
			float val = (ls.tok.tag==TokenLParen || ls.tok.tag==TokenLBrack)? ParseFnExpr(ls, expression, fn_math, data) : ParsePowExpr(ls, expression, fn_math, data);
			return float( GetRandomInt(0, RoundFloat(val)) );
		}
	}
	return ParsePrefixExpr(ls, expression, fn_math, data);
}

/// Factor  = number | ident | '(' Expr ')' | '[' Expr ']' .
static stock float ParseFactor(LexState ls, const char[] expression, ConfigMapMathVarFunc fn_math=INVALID_FUNCTION, any data=0) {
	float __NAN__ = view_as< float >(view_as< any >( -1 ));
	switch( ls.tok.tag ) {
		case TokenNum: {
			float f = ls.tok.val;
			GetToken(ls, expression);
			return f;
		}
		case TokenVar: {
			char lexeme[LEXEME_SIZE]; lexeme = ls.tok.lexeme;
			int len = ls.tok.size;
			GetToken(ls, expression);
			
			float f = __NAN__;
			/// void(const char[] var_name, int var_name_len, float &f, any data);
			if( view_as< any >(f) == -1 && fn_math != INVALID_FUNCTION ) {
				Call_StartFunction(null, fn_math);
				Call_PushString(lexeme);
				Call_PushCell(len);
				Call_PushFloatRef(f);
				Call_PushCell(data);
				Call_Finish();
			}
			return f;
		}
		case TokenE: {
			GetToken(ls, expression);
			/// from `expf(1.f);`
			any eulers_constant_hex = 0x402df854;
			return eulers_constant_hex;
		}
		case TokenPi: {
			GetToken(ls, expression);
			/// from `acosf(-1.f);`
			any pi_hex = 0x40490fdb;
			return pi_hex;
		}
		case TokenURand: {
			GetToken(ls, expression);
			return GetURandomFloat();
		}
		case TokenLParen: {
			GetToken(ls, expression);
			float f = ParseAddExpr(ls, expression, fn_math, data);
			if( ls.tok.tag != TokenRParen ) {
				LogError("ConfigMap-Math :: expected ')' bracket but got '%s'", ls.tok.lexeme);
				return __NAN__;
			}
			GetToken(ls, expression);
			return f;
		}
		case TokenLBrack: {
			GetToken(ls, expression);
			float f = ParseAddExpr(ls, expression, fn_math, data);
			if( ls.tok.tag != TokenRBrack ) {
				LogError("ConfigMap-Math :: expected ']' bracket but got '%s'", ls.tok.lexeme);
				return __NAN__;
			}
			GetToken(ls, expression);
			return f;
		}
	}
	return __NAN__;
}

static stock bool LexDec(LexState ls, const char[] expression) {
	int lit_flags = 0;
	while( expression[ls.i] != 0 && (IsCharNumeric(expression[ls.i]) || expression[ls.i]=='.') ) {
		switch( expression[ls.i] ) {
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
			}
			case '.': {
				if( lit_flags & dot_flag ) {
					LogError("ConfigMap-Math :: extra dot in decimal literal");
					return false;
				}
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				lit_flags |= dot_flag;
			}
			default: {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				LogError("ConfigMap-Math :: invalid decimal literal: '%s'", ls.tok.lexeme);
				return false;
			}
		}
	}
	return true;
}

static stock void GetToken(LexState ls, const char[] expression, bool &res=true) {
	int len = strlen(expression);
	Token empty; ls.tok = empty;
	while( ls.i < len ) {
		switch( expression[ls.i] ) {
			case ' ', '\t', '\n', '\r': {
				ls.i++;
			}
			case '0': { /// possible hex, octal, binary, or float.
				ls.tok.tag = TokenNum;
				ls.i++;
				switch( expression[ls.i] ) {
					/*
					case 'b', 'B': {
						/// Binary.
						ls.i++;
						if( LexBinary(ls, expression) ) {
							ls.tok.val = StringToInt(ls.tok.lexeme, 2) + 0.0;
						}
						return;
					}
					case 'o', 'O': {
						/// Octal.
						ls.i++;
						if( LexOctal(ls, expression) ) {
							ls.tok.val = StringToInt(ls.tok.lexeme, 8) + 0.0;
						}
						return;
					}
					case 'x', 'X': {
						/// Hex.
						ls.i++;
						if( LexHex(ls, expression) ) {
							ls.tok.val = StringToInt(ls.tok.lexeme, 16) + 0.0;
						}
						return;
					}*/
					case '.', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': {
						/// Decimal/Float.
						if( LexDec(ls, expression) ) {
							ls.tok.val = StringToFloat(ls.tok.lexeme);
						}
						return;
					}
				}
			}
			case '.', '1', '2', '3', '4', '5', '6', '7', '8', '9': {
				ls.tok.tag = TokenNum;
				/// Decimal/Float.
				if( LexDec(ls, expression) ) {
					ls.tok.val = StringToFloat(ls.tok.lexeme);
				}
				return;
			}
			case '(': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenLParen;
				return;
			}
			case ')': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenRParen;
				return;
			}
			case '[': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenLBrack;
				return;
			}
			case ']': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenRBrack;
				return;
			}
			case '+': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenPlus;
				return;
			}
			case '-': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenSub;
				return;
			}
			case '*': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenMul;
				return;
			}
			case '/': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenDiv;
				return;
			}
			case '^': {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				ls.tok.tag = TokenPow;
				return;
			}
			case 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z': {
				while( expression[ls.i] != 0 && (IsCharAlpha(expression[ls.i]) || expression[ls.i]=='_') ) {
					ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				}
				
				static const char builtin_names[][] = {
					"sin", "cos", "tan",
					"arcsin", "arccos", "arctan",
					"log", "floor", "round", "ceil", "fraction",
					"radians", "degress", "random", "irandom",
					
					/// variables
					"e", "pi", "urand"
				};
				
				int builtin_name = TokenSin;
				for( int i; i < sizeof(builtin_names); i++ ) {
					if( StrEqual(ls.tok.lexeme, builtin_names[i]) ) {
						ls.tok.tag = builtin_name;
						return;
					}
					builtin_name++;
				}
				ls.tok.tag = TokenVar;
				return;
			}
			default: {
				ls.tok.lexeme[ls.tok.size++] = expression[ls.i++];
				LogError("ConfigMap-Math :: invalid expression token '%s'.", ls.tok.lexeme);
				res = false;
				return;
			}
		}
	}
}