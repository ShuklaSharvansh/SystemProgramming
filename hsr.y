//headers and extern functions
%{
#include <string>
#include <string.h>
#include <iostream>
#include "hsr.tab.h"
#include "sqlite3.h"
extern int yylex();
extern void yyerror(std::string);
void Div0Error(void);
void UnknownVarError(std::string);
void swap(char *);
void exchange(char *);
%}


//token definitions for flex
%union {
int int_val;
double double_val;
char *str_val;
}
%token < int_val > PLUS MINUS MULTIPLY DIVIDE LPAREN RPAREN EOL
%token < str_val > VARIABLE
%token < double_val > NUMBER
%start root

//parsing tree basically
%%
root: lines;
lines: lines line | line;
line:expression{};

expression: expression PLUS expression {}
| expression MINUS expression {}
| expression MULTIPLY expression {}
| expression DIVIDE expression {}
| LPAREN expression RPAREN {}
| unitcalc {}
;
unitcalc: VARIABLE {swap($1);}  //baking the swapping right into the grammar
| NUMBER
;

%%


std::string var[10];    //this array will store the variable names for corresponding placeholders
int count = 0;

static int callback1(void *data, int argc, char **argv, char **azColName)  //will execute query to fetch colname for given varname
{
    var[count] = std::string(argv[0]);         //the actual storing statement 
    count++;
    return 0;
}
static int callback2(void *data, int argc, char **argv, char **azColName)  //second callback to actually output the result of the final query 
{
    std::cout<<"\n\t"<<argv[0];
    return 0;
}

void swap(char* x)           //this function extracts the placeholders and calls sql to swap them
{
    std::string st(x);
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    std::string sql;
    
    rc = sqlite3_open("sys_prog.db", &db);
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        exit(0);
    }
    sql = "SELECT colname FROM formula_fields WHERE varname = \"" + st + "\";";
    rc = sqlite3_exec(db, sql.c_str(), callback1, 0, &zErrMsg);
    sqlite3_close(db);
}

void exchange(char* form)         //gets the corrected formula, and also calls the required query to fetch final output
{
    int j=0;
    std::string finalquery = "SELECT ";
    std::cout<<"\n\nThis is the selected formula, it is correct don't worry: \n";
    std::cout<<form<<"\n\n";
    for(int i=0;form[i]!='\0';i++)       //loop reads the formula, as soon as a variable is found, the final string named finalquery
    {                                       //adds the fieldname stored in var in order, else it saves whatever is in formula
        if(form[i]=='<')
        {
            finalquery = finalquery + var[j];
            j++;
            while(form[i]!='>')
                i++;
        }
        else
            finalquery += form[i];
    }
    std::cout<<"\nEnter salary id: ";      //salary table has multiple values
    char sal;
    std::cin>>sal;
    finalquery += " FROM salary WHERE id = ";           //complete the query
    finalquery.push_back(sal);
    finalquery.push_back(';');
    std::cout<<"\n\nFormula has been altered to fit, this is the required SQL Query: \n";     //call for the final output
    std::cout<<finalquery;
    std::cout<<"\n\nWhich produces the following output: \n";
    sqlite3 *db;
    char *zErrMsg = 0;
    int rc;
    rc = sqlite3_open("sys_prog.db", &db);
    if(rc)
    {
        std::cout << "DB Error: " << sqlite3_errmsg(db);
        sqlite3_close(db);
        exit(0);
    }
    rc = sqlite3_exec(db, finalquery.c_str(), callback2, 0, &zErrMsg);
    sqlite3_close(db);
}