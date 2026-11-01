/*  An ongoing project to convert html  
 *  exported from Google Docs into a book
 *  with cover page, table of contents, 
 *  chapters, and page numbers. 
 *  
 *  Functions to be built:
 *    adding running headers 
 *    automating html entity conversions
 *    adding back cover, back matter (colophon, index)
 *    add ul/ol styling option
 *    add bolding/italics
 *
 *  Enjoy & share updates! 
 */
import processing.pdf.*;
PGraphicsPDF pdf;
String[] htmlFile; //html unzips as a single line, so loadStrings() will put everything in htmlFile[0]
String[][] parsedHTML;
String htmlParserRegex = "(?:<(?<listType>ul|ol) class=\"(?<listClass>.*?)\">)*<(?<tag>p|h\\d|li) class=\"(?<tagClass>.*?)\".*?><span.*?>(?<content>.*?)<\\/span>(?:<span.*?>(?<content2>.*?)<\\/span>)*<\\/(?:p|h\\d|li)>";

int PDFnum = 1; //keeps track of # pages in entire PDF OUTPUT (not printed page number), increments by 1 each time startNewPage() is called
int frontNum = 1; //keeps track of # frontmatter pages. Difference between PDFnum and frontNum is the official printed page number
boolean pageEven = false; //toggles back and forth each time startNewPage() is called

//PAGE SETUP **********************************************************************************************************************************
float inch = 72;
float pageW = 5.5;
float pageH = 8.5;
float marginTop = inch*0.375;
float marginBottom = inch*0.75;
float marginLeft = inch*0.5;
float marginRight = inch*0.5;

//SET TYPE STYLES **********************************************************************************************************************************
PFont GrotesqueMTReg;
PFont GrotesqueMTBold;
PFont GrotesqueMTLight;
PFont curFont;
int curLeading = 14; //leading is the vertical space (y) between lines of text (printPosY)
int sizeTitle = 44;
int sizeSubtitle = 11;
int sizeBody = 11;
int sizeH1 = 48;
int sizeH2 = 11;
int sizeSmall = 9; //not used currently, could be for footnotes, etc

//text area setup
float textW = pageW*inch - (marginLeft + marginRight);
float textH = pageH*inch - (marginTop + marginBottom);
float printPosX = marginLeft; //current x position of next text to be printed, resets to marginLeft with each new page
float printPosY = marginTop; //current y position of next text to be printed, resets to marginTop with each new page (NOTE: this marks the TOP of the text, bottom of text printed is printPosY+curLeading)

StringList TOC;
boolean TOCready = false; //set to true after titles and/or subtitles are printed

void setup() { 
  size(396, 612, PDF, "debtofcare_book.pdf"); //CHANGE OUTPUT PDF FILENAME HERE ****************************************************
  pdf = (PGraphicsPDF) g; 
  pixelDensity(1); //need to specify this on hires screens otherwise frame is displayed incorrectly
  
  //load fonts
  GrotesqueMTBold = createFont("fonts/GrotesqueMT-Bold.otf", sizeBody);
  GrotesqueMTLight = createFont("fonts/GrotesqueMT-Light.otf", sizeBody);
  GrotesqueMTReg = createFont("fonts/GrotesqueMT.otf", sizeBody);
  
  noLoop(); //run draw() only once
  TOC = new StringList();
  htmlFile = loadStrings("debtofcare 5.html"); //CHANGE INPUT FILENAME HERE ******************************************************************************
  parsedHTML = matchAll(htmlFile[0], htmlParserRegex); //matchAll() returns regex matches as rows and groups within the match as columns
  getTOC(); //presaves headings for TOC
}

void draw() {
  
  //some initial settings, need to update all values BOTH HERE AND FURTHER BELOW ******************************************************************************
  background(255); //background will cover everything drawn before it (unless has alpha value)
  fill(0); //specifies the color of the next "shape" to be drawn, in this case all the text. Remains same until overwritten with new value. Needs to be called each time you want color changed.
  drawBackground1(); //draws grid pattern -- REPLACE/REMOVE **************************************************************************************************
  textFont(GrotesqueMTReg); //like fill(), needs to be called before text is drawn to set font style
  textLeading(curLeading);
  printPages(); 
  fillEndPages(); //add blank pages until mult of 4
  exit(); 
}

void getTOC() { //currently grabs all H2 elements
  for (int i=0; i < parsedHTML.length; i++) { //check through all regex matches
    if (parsedHTML[i][3].equals("h2")) TOC.append(parsedHTML[i][5]); //add H2s to TOC StringList, can update to other tags **************************
  }
}

void printPages(){ //goes through each regex  match one by one and prints, including overflow onto the next page
  for (int i=0; i < parsedHTML.length; i++) { 
    if (!onCover(parsedHTML[i][4], i)){//check if match is onCover (title/subtitle) 
      if (TOCready){ //if current match ISN'T title/subtitle AND title/subtitle has already been printed, return true
        printTOC();   //to print TOC
      }
      if (parsedHTML[i][3].equals("h1")) {
        if (printPosY > marginTop) { //if printPosY is already at top, no need to add extra page
          startNewPage();
          printPageNum();
        }
        if (pageEven){ //add an extra page so h1 always starts on right hand page
          startNewPage();
          printPageNum();
        }
        printCurMatch(parsedHTML[i][5]); 
        //can add another page here so that h1 is a chapter title page, and content starts on following page
      }
      else if (parsedHTML[i][3].equals("p")){
        curLeading = 14;
        textSize(sizeBody);
        printCurMatch(parsedHTML[i][5]);
      }
      else if (parsedHTML[i][3].equals("h2")){
        curLeading = 14; 
        textSize(sizeH2);
        printCurMatch(parsedHTML[i][5]);
      }
      else if (parsedHTML[i][3].equals("h3")){
        //h3 type styles
        printCurMatch(parsedHTML[i][5]);
      }
      else if (parsedHTML[i][3].equals("h4")){
        //h4 type styles
        printCurMatch(parsedHTML[i][5]);
      }
    }
  }
}

boolean onCover(String textIn, int matchIndex){ //prints title and subtitle
  String[] tagClassChecker = split(textIn, " "); //splits tagClass group into each class label, to check if matches title or subtitle
  for (int j = 0; j < tagClassChecker.length; j++){
    if (tagClassChecker[j].equals("title")) {
      printPosY+=  4; //shifts title down a little -- REMOVE **********************************************************************************************
      marginRight = marginRight+80; //pushes margin in from right -- REMOVE ******************************************************************************
      textSize(sizeTitle);
      curLeading = 56; //leading needs to be updated inline each time textSize is changed, can create global variables for each **************************
      printCurMatch(parsedHTML[matchIndex][5]);
      marginRight = marginRight-80; //resets margin for subtitle -- REMOVE ******************************************************************************
      TOCready = true;
      return true;
    }
    else if (tagClassChecker[j].equals("subtitle")) {
      printPosY-=4; //shifts subtitle down a little -- REMOVE *********************************************************************************************
      textSize(sizeSubtitle);
      curLeading = 14;
      printCurMatch(parsedHTML[matchIndex][5]);
      TOCready = true;
      return true;
    }
  }
  return false;
}

void printTOC(){
  startNewPage(); 
  startNewPage(); //inserts one blank page after cover for the inside cover page
  frontNum += 2; //update frontmatter count
  TOCready = false; //TOC done, won't get reprinted
  printPosX = marginLeft+(textW/4); //currently indents TOC by 1/4 column
  for (int i = 0; i < TOC.size(); i++){
    printCurMatch(TOC.get(i)); //prints TOC line by line
  }
  startNewPage(); //starts new page after TOC
  frontNum++;
  if (pageEven){
    startNewPage(); //adds another page so that main text starts on a right hand page
  }
  printPageNum(); //page#s need to print first after a new page is started, before text is printed, in case of overflow
}

void printCurMatch(String textIn){ //print entirety of textIn, including overflow, by estimating height/width of String before overflow, saving the index, and printing in two parts
  textLeading(curLeading); 
  float curY = printPosY; //saves starting printPosY for printing current textIn, printPosY gets updated for following match
  float yTest = printPosY; //gets starting x and y pos for overflow testing
  float xTest = printPosX;
  int overflowIndex = 0;
  String[] wordsToCheck = split(textIn, " "); //splits text to print into words
  for (int i = 0 ; i < wordsToCheck.length; i++){
    if (wordsToCheck[i].length()>0){
      float whitespace1 = (GrotesqueMTReg.width(wordsToCheck[i].charAt(wordsToCheck[i].length() - 1)) * GrotesqueMTReg.getSize() 
      - GrotesqueMTReg.getGlyph(wordsToCheck[i].charAt(wordsToCheck[i].length() - 1)).width) / 2; // get whitespace of last character
      float whitespace2 = (GrotesqueMTReg.width(wordsToCheck[i].charAt(0)) * GrotesqueMTReg.getSize() - GrotesqueMTReg.getGlyph(wordsToCheck[i].charAt(0)).width) / 2; //get whitespace of first character
      xTest += textWidth(wordsToCheck[i]) - whitespace1 - whitespace2 + textWidth(" "); //estimates width of each word, followed by single space
  
      if (xTest > width-marginRight-10 ){ //if current wordToCheck width crosses marginRight-10, adjust as needed ******************************************
        yTest += curLeading; //move to next line
        if (yTest+curLeading > height-marginBottom){ //if next line crosses marginBottom, it's GONNA OVERFLOW~~
          text(textIn.substring(0, overflowIndex), printPosX, curY, width-marginRight-printPosX, height-curY-marginBottom); //print textIn up to the overflowIndex on current page
          println(textIn.substring(0, overflowIndex)); //print this text to console to check if there are errors
          startNewPage(); //start new page
          printPageNum();
          printCurMatch(textIn.substring(overflowIndex)); //print rest of textIn after the overflowIndex, but check for overflows again
          return;
        }
        else {
          xTest = textWidth(wordsToCheck[i]) + textWidth(" ") - whitespace1 - whitespace2; //current wordToCheck moved to next line, reset xTest to just this width
          printPosY += curLeading; //keep printPosY updated for the next match
        }
      }
      else {
        xTest += textWidth(" "); //technically extra, but overflowIndex is more accurate with it ***********************************************************
      }
      overflowIndex += wordsToCheck[i].length()+1; //current wordToCheck didn't overflow, update overflowIndex to after current wordToCheck
    }
  }
  text(textIn, printPosX, curY, width-marginRight-printPosX, height-curY-marginBottom); //finished checking entire textIn without any overflow, print everything
  printPosY += curLeading*2; //add blank line after each match
}

void printRunners(){
  //print section runner
  //update section runner index
}

void printPageNum(){
  text(PDFnum-frontNum, marginLeft, marginTop+textH+curLeading*2); //change page num position here ****************************************************
}

void startNewPage(){
  pdf.nextPage(); //save current frame as PDF page & start next page
  printPosY = marginTop; 
  printPosX = marginLeft; 
  PDFnum++;
  if (pageEven){
    pageEven = false;
  }
  else pageEven = true;
  background(255); //set background color for new page here ******************************************************************************************
  drawBackground1(); //draws grid pattern on all subsequent pages -- REMOVE **************************************************************************
}

void fillEndPages(){
  int remainder = ((int(PDFnum/4)+1)*4)-PDFnum;
  if (remainder < 4){
    for (int i = 0; i < remainder; i++){
      startNewPage();
    }
  }
}

//grid pattern every 14px between the margins
void drawBackground1(){
  for (float i = marginLeft; i < width-marginRight ; i += 14){
    stroke(2,40);
    line(i,0, i, height);
  }
  for (float i = marginTop+curLeading-6; i < height-marginBottom; i +=14){
    line(0,i,width,i);
  }
}
