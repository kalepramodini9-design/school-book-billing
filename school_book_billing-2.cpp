/*
 School Book Billing App - C++17, No Server
 -------------------------------------------
 Local desktop/console version.
 Data is stored in CSV files in the same folder:
   schools.csv
   standards.csv
   books.csv
   stationery.csv
   invoices.csv
   invoice_items.csv

 Build on Windows:
   g++ -std=c++17 school_billing.cpp -o school_billing.exe

 Or in Visual Studio:
   Create a Console App and replace the generated .cpp with this file.

 This version has NO server and NO database server.
*/

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <iomanip>
#include <ctime>
#include <algorithm>
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

struct School {
    int id{};
    string name;
};

struct Standard {
    int id{};
    int schoolId{};
    string year;
    string name;
};

struct Item {
    int id{};
    int schoolId{};
    string year;
    int standardId{};
    int sr{};
    string name;
    string subject; // blank for stationery
    double price{};
    bool textbook{};
};

struct SelectedItem {
    string section;
    int sr{};
    string name;
    string subject;
    double price{};
    int qty{};
    double amount{};
};

struct Invoice {
    string invoiceNo;
    string date;
    string student;
    string mobile;
    string school;
    string year;
    string standard;
    vector<SelectedItem> items;
    double textbookTotal{};
    double stationeryTotal{};
    double grandTotal{};
};

vector<School> schools;
vector<Standard> standards;
vector<Item> items;
vector<Invoice> invoices;

string trim(const string& s) {
    size_t a = s.find_first_not_of(" \t\r\n");
    size_t b = s.find_last_not_of(" \t\r\n");
    if (a == string::npos) return "";
    return s.substr(a, b-a+1);
}

string csvEscape(const string& s) {
    string x = s;
    bool quote = x.find(',') != string::npos || x.find('"') != string::npos;
    size_t p = 0;
    while ((p = x.find('"', p)) != string::npos) {
        x.insert(p, 1, '"');
        p += 2;
    }
    return quote ? "\"" + x + "\"" : x;
}

vector<string> csvSplit(const string& line) {
    vector<string> out;
    string cur;
    bool quoted = false;
    for (size_t i=0; i<line.size(); ++i) {
        char c=line[i];
        if(c=='"') {
            if(quoted && i+1<line.size() && line[i+1]=='"') {
                cur.push_back('"'); ++i;
            } else quoted=!quoted;
        } else if(c==',' && !quoted) {
            out.push_back(cur); cur.clear();
        } else cur.push_back(c);
    }
    out.push_back(cur);
    return out;
}

string nowDate() {
    time_t t=time(nullptr);
    tm lt{};
#ifdef _WIN32
    localtime_s(&lt,&t);
#else
    lt=*localtime(&t);
#endif
    ostringstream o;
    o << setfill('0') << setw(2) << lt.tm_mday << "-"
      << setw(2) << lt.tm_mon+1 << "-" << lt.tm_year+1900;
    return o.str();
}

string money(double n) {
    ostringstream o;
    o << fixed << setprecision(2) << n;
    return o.str();
}

int nextIdSchool() {
    int m=0; for(auto& x:schools) m=max(m,x.id); return m+1;
}
int nextIdStandard() {
    int m=0; for(auto& x:standards) m=max(m,x.id); return m+1;
}
int nextIdItem() {
    int m=0; for(auto& x:items) m=max(m,x.id); return m+1;
}

void saveAll() {
    {
        ofstream f("schools.csv");
        f<<"id,name\n";
        for(auto& x:schools) f<<x.id<<","<<csvEscape(x.name)<<"\n";
    }
    {
        ofstream f("standards.csv");
        f<<"id,schoolId,year,name\n";
        for(auto& x:standards) f<<x.id<<","<<x.schoolId<<","<<csvEscape(x.year)<<","<<csvEscape(x.name)<<"\n";
    }
    {
        ofstream f("books.csv");
        f<<"id,schoolId,year,standardId,sr,name,subject,price\n";
        for(auto& x:items) if(x.textbook)
            f<<x.id<<","<<x.schoolId<<","<<csvEscape(x.year)<<","<<x.standardId<<","<<x.sr<<","
             <<csvEscape(x.name)<<","<<csvEscape(x.subject)<<","<<x.price<<"\n";
    }
    {
        ofstream f("stationery.csv");
        f<<"id,schoolId,year,standardId,sr,name,price\n";
        for(auto& x:items) if(!x.textbook)
            f<<x.id<<","<<x.schoolId<<","<<csvEscape(x.year)<<","<<x.standardId<<","<<x.sr<<","
             <<csvEscape(x.name)<<","<<x.price<<"\n";
    }
    {
        ofstream f("invoices.csv");
        f<<"invoiceNo,date,student,mobile,school,year,standard,textbookTotal,stationeryTotal,grandTotal\n";
        for(auto& x:invoices)
            f<<csvEscape(x.invoiceNo)<<","<<csvEscape(x.date)<<","<<csvEscape(x.student)<<","
             <<csvEscape(x.mobile)<<","<<csvEscape(x.school)<<","<<csvEscape(x.year)<<","
             <<csvEscape(x.standard)<<","<<x.textbookTotal<<","<<x.stationeryTotal<<","<<x.grandTotal<<"\n";
    }
    {
        ofstream f("invoice_items.csv");
        f<<"invoiceNo,section,sr,name,subject,price,qty,amount\n";
        for(auto& inv:invoices)
            for(auto& x:inv.items)
                f<<csvEscape(inv.invoiceNo)<<","<<csvEscape(x.section)<<","<<x.sr<<","
                 <<csvEscape(x.name)<<","<<csvEscape(x.subject)<<","<<x.price<<","<<x.qty<<","<<x.amount<<"\n";
    }
}

bool fileExists(const string& p){return fs::exists(p);}

void seedData() {
    if(fileExists("schools.csv")) return;

    schools.push_back({1,"Venus World School"});
    standards.push_back({1,1,"2026-27","4th Standard"});

    vector<pair<string,pair<string,double>>> b = {
        {"Spendid Science",{"Science",575}}, {"The World Around Us",{"Science",490}},
        {"Maths Milestone",{"Mathematics",585}}, {"Level Up Vantage",{"English",610}},
        {"English Grammer",{"English",430}}, {"Shivai",{"Marathi",290}},
        {"Maitri Vyakaran",{"Marathi",180}}, {"Veena",{"Hindi",430}},
        {"Dyanmay-Grammar",{"Hindi",415}}, {"Computer Science Success",{"Computer",395}},
        {"The GK Odyssey",{"GK",398}}, {"Art Smart Drawing",{"Drawing",180}},
        {"Chatrapati Shivaji Maharaj",{"EVS Textbook 2",68}}
    };
    int id=1,sr=1;
    for(auto& p:b) items.push_back({id++,1,"2026-27",1,sr++,p.first,p.second.first,p.second.second,true});

    vector<pair<string,double>> n = {
        {"1 Line Notebook 100 Pages",25},{"1 Line Notebook 200 Pages",50},
        {"2 Line Notebook 200 Pages",50},{"Drawing Book A4 size",65},
        {"Crayon Colour 12 Shades",35}
    };
    sr=1;
    for(auto& p:n) items.push_back({id++,1,"2026-27",1,sr++,p.first,"",p.second,false});
    saveAll();
}

void loadAll() {
    schools.clear(); standards.clear(); items.clear(); invoices.clear();

    ifstream fs1("schools.csv");
    string line;
    getline(fs1,line);
    while(getline(fs1,line)) {
        auto v=csvSplit(line); if(v.size()>=2) schools.push_back({stoi(v[0]),v[1]});
    }

    ifstream fs2("standards.csv"); getline(fs2,line);
    while(getline(fs2,line)) {
        auto v=csvSplit(line); if(v.size()>=4) standards.push_back({stoi(v[0]),stoi(v[1]),v[2],v[3]});
    }

    ifstream fs3("books.csv"); getline(fs3,line);
    while(getline(fs3,line)) {
        auto v=csvSplit(line); if(v.size()>=8)
            items.push_back({stoi(v[0]),stoi(v[1]),v[2],stoi(v[3]),stoi(v[4]),v[5],v[6],stod(v[7]),true});
    }

    ifstream fs4("stationery.csv"); getline(fs4,line);
    while(getline(fs4,line)) {
        auto v=csvSplit(line); if(v.size()>=7)
            items.push_back({stoi(v[0]),stoi(v[1]),v[2],stoi(v[3]),stoi(v[4]),v[5],"",stod(v[6]),false});
    }

    ifstream fi("invoices.csv");
    if(fi) {
        getline(fi,line);
        while(getline(fi,line)) {
            auto v=csvSplit(line); if(v.size()>=10) {
                Invoice x;
                x.invoiceNo=v[0]; x.date=v[1]; x.student=v[2]; x.mobile=v[3];
                x.school=v[4]; x.year=v[5]; x.standard=v[6];
                x.textbookTotal=stod(v[7]); x.stationeryTotal=stod(v[8]); x.grandTotal=stod(v[9]);
                invoices.push_back(x);
            }
        }
    }

    ifstream ff("invoice_items.csv");
    if(ff) {
        getline(ff,line);
        while(getline(ff,line)) {
            auto v=csvSplit(line); if(v.size()>=8) {
                for(auto& inv:invoices) if(inv.invoiceNo==v[0]) {
                    inv.items.push_back({v[1],stoi(v[2]),v[3],v[4],stod(v[5]),stoi(v[6]),stod(v[7])});
                    break;
                }
            }
        }
    }
}

void pause() {
    cout<<"\nPress ENTER to continue...";
    string x; getline(cin,x);
}

int chooseSchool() {
    cout<<"\nSchools:\n";
    for(size_t i=0;i<schools.size();++i) cout<<i+1<<". "<<schools[i].name<<"\n";
    cout<<"Select: ";
    int n; cin>>n; cin.ignore();
    if(n<1 || n>(int)schools.size()) return -1;
    return schools[n-1].id;
}

string chooseYear() {
    vector<string> years;
    for(auto& s:standards) if(find(years.begin(),years.end(),s.year)==years.end()) years.push_back(s.year);
    cout<<"\nAcademic Years:\n";
    for(size_t i=0;i<years.size();++i) cout<<i+1<<". "<<years[i]<<"\n";
    cout<<"Select: ";
    int n; cin>>n; cin.ignore();
    if(n<1 || n>(int)years.size()) return "";
    return years[n-1];
}

int chooseStandard(int schoolId,const string& year) {
    vector<Standard> v;
    for(auto& s:standards) if(s.schoolId==schoolId && s.year==year) v.push_back(s);
    cout<<"\nStandards:\n";
    for(size_t i=0;i<v.size();++i) cout<<i+1<<". "<<v[i].name<<"\n";
    cout<<"Select: ";
    int n; cin>>n; cin.ignore();
    if(n<1 || n>(int)v.size()) return -1;
    return v[n-1].id;
}

string nextInvoice() {
    return "INV-" + to_string(1900 + (localtime(&(time_t){time(nullptr)}))->tm_year)
        + "-" + [&](){ostringstream o;o<<setfill('0')<<setw(4)<<invoices.size()+1;return o.str();}();
}

void printInvoice(const Invoice& x) {
    cout<<"\n============================================================\n";
    cout<<"                  "<<x.school<<"\n";
    cout<<"                   BOOK LIST "<<x.year<<"\n";
    cout<<"                    "<<x.standard<<"\n";
    cout<<"============================================================\n";
    cout<<"Invoice No: "<<x.invoiceNo<<"    Date: "<<x.date<<"\n";
    cout<<"Student: "<<x.student<<"    Mobile: "<<x.mobile<<"\n\n";

    cout<<"TEXTBOOKS (A)\n";
    cout<<left<<setw(6)<<"Sr"<<setw(34)<<"Name"<<setw(18)<<"Subject"
        <<right<<setw(8)<<"Price"<<setw(7)<<"Qty"<<setw(12)<<"Amount"<<"\n";
    cout<<string(85,'-')<<"\n";
    for(auto& i:x.items) if(i.section=="TextBooks")
        cout<<left<<setw(6)<<i.sr<<setw(34)<<i.name.substr(0,33)<<setw(18)<<i.subject.substr(0,17)
            <<right<<setw(8)<<money(i.price)<<setw(7)<<i.qty<<setw(12)<<money(i.amount)<<"\n";
    cout<<string(85,'-')<<"\n";
    cout<<right<<setw(83)<<"Total (A): "<<money(x.textbookTotal)<<"\n\n";

    cout<<"NOTEBOOK AND STATIONARY (B)\n";
    cout<<left<<setw(6)<<"Sr"<<setw(42)<<"Name"<<right<<setw(12)<<"Price"<<setw(8)<<"Qty"<<setw(14)<<"Amount"<<"\n";
    cout<<string(85,'-')<<"\n";
    for(auto& i:x.items) if(i.section!="TextBooks")
        cout<<left<<setw(6)<<i.sr<<setw(42)<<i.name.substr(0,41)
            <<right<<setw(12)<<money(i.price)<<setw(8)<<i.qty<<setw(14)<<money(i.amount)<<"\n";
    cout<<string(85,'-')<<"\n";
    cout<<right<<setw(83)<<"Total (B): "<<money(x.stationeryTotal)<<"\n";
    cout<<right<<setw(83)<<"GRAND TOTAL: "<<money(x.grandTotal)<<"\n";
    cout<<"============================================================\n";
}

void createBill() {
    if(schools.empty() || standards.empty()) { cout<<"Please add school and standard first.\n"; return; }

    Invoice inv;
    cout<<"\nStudent Name: "; getline(cin,inv.student);
    cout<<"Mobile No.: "; getline(cin,inv.mobile);

    int sid=chooseSchool(); if(sid<0)return;
    string year=chooseYear(); if(year.empty())return;
    int stid=chooseStandard(sid,year); if(stid<0)return;

    auto sit=find_if(schools.begin(),schools.end(),[&](auto&s){return s.id==sid;});
    auto st=find_if(standards.begin(),standards.end(),[&](auto&s){return s.id==stid;});
    inv.school=sit->name; inv.year=year; inv.standard=st->name;
    inv.date=nowDate(); inv.invoiceNo=nextInvoice();

    vector<Item> available;
    for(auto& x:items) if(x.schoolId==sid && x.year==year && x.standardId==stid) available.push_back(x);

    cout<<"\nSelect books/stationery. Enter quantity 0 to skip.\n";
    for(auto& x:available) {
        cout<<"\n["<<(x.textbook?"TextBook":"Stationery")<<"] "<<x.sr<<". "<<x.name;
        if(x.textbook) cout<<" ("<<x.subject<<")";
        cout<<" - Price "<<money(x.price)<<"\n";
        cout<<"Quantity: ";
        int q; cin>>q;
        if(q>0) {
            SelectedItem si;
            si.section=x.textbook?"TextBooks":"Notebook and Stationary";
            si.sr=x.sr; si.name=x.name; si.subject=x.subject; si.price=x.price; si.qty=q; si.amount=x.price*q;
            inv.items.push_back(si);
            if(x.textbook) inv.textbookTotal+=si.amount; else inv.stationeryTotal+=si.amount;
        }
    }
    cin.ignore();
    inv.grandTotal=inv.textbookTotal+inv.stationeryTotal;

    if(inv.items.empty()){cout<<"No items selected. Bill cancelled.\n";return;}
    invoices.push_back(inv);
    saveAll();

    printInvoice(inv);

    // Also create a simple text invoice file for printing/saving.
    string filename=inv.invoiceNo+".txt";
    ofstream f(filename);
    if(f) {
        f<<"School: "<<inv.school<<"\nBook List "<<inv.year<<"\n"<<inv.standard<<"\n";
        f<<"Invoice: "<<inv.invoiceNo<<"\nDate: "<<inv.date<<"\nStudent: "<<inv.student<<"\nMobile: "<<inv.mobile<<"\n\n";
        for(auto& i:inv.items)
            f<<i.section<<" | "<<i.sr<<" | "<<i.name<<" | "<<i.subject<<" | "<<i.price<<" | "<<i.qty<<" | "<<i.amount<<"\n";
        f<<"TextBooks Total: "<<inv.textbookTotal<<"\nStationery Total: "<<inv.stationeryTotal<<"\nGrand Total: "<<inv.grandTotal<<"\n";
    }
    cout<<"\nBill saved locally as "<<filename<<" and in invoices.csv.\n";
    pause();
}

void addSchool() {
    string n; cout<<"School name: "; getline(cin,n);
    if(n.empty())return;
    schools.push_back({nextIdSchool(),n}); saveAll(); cout<<"School added.\n";
}

void addStandard() {
    int sid=chooseSchool(); if(sid<0)return;
    string y=chooseYear(); if(y.empty()){cout<<"Enter academic year manually: ";getline(cin,y);}
    string n; cout<<"Standard name: ";getline(cin,n);
    standards.push_back({nextIdStandard(),sid,y,n}); saveAll(); cout<<"Standard added.\n";
}

void addItem(bool textbook) {
    int sid=chooseSchool(); if(sid<0)return;
    string y=chooseYear(); if(y.empty()){cout<<"Academic year: ";getline(cin,y);}
    int stid=chooseStandard(sid,y); if(stid<0)return;
    string n,sub; double p; int sr;
    cout<<"Sr.No: ";cin>>sr;cin.ignore();
    cout<<"Item name: ";getline(cin,n);
    if(textbook){cout<<"Subject: ";getline(cin,sub);}
    cout<<"Price: ";cin>>p;cin.ignore();
    items.push_back({nextIdItem(),sid,y,stid,sr,n,sub,p,textbook});
    saveAll(); cout<<"Item added.\n";
}

void history() {
    if(invoices.empty()){cout<<"No bills yet.\n";pause();return;}
    cout<<"\nBill History\n";
    for(auto it=invoices.rbegin();it!=invoices.rend();++it)
        cout<<it->invoiceNo<<" | "<<it->date<<" | "<<it->student<<" | "<<it->school
            <<" | "<<it->standard<<" | "<<money(it->grandTotal)<<"\n";
    cout<<"\nEnter invoice number to view, or press ENTER: ";
    string n;getline(cin,n);
    if(!n.empty()){
        auto it=find_if(invoices.begin(),invoices.end(),[&](auto&x){return x.invoiceNo==n;});
        if(it!=invoices.end())printInvoice(*it); else cout<<"Invoice not found.\n";
    }
    pause();
}

void reports() {
    double total=0; for(auto& x:invoices) total+=x.grandTotal;
    cout<<"\nREPORTS\n";
    cout<<"Total Bills : "<<invoices.size()<<"\n";
    cout<<"Total Sales : "<<money(total)<<"\n";
    cout<<"Schools     : "<<schools.size()<<"\n";
    cout<<"Standards   : "<<standards.size()<<"\n";
    cout<<"Items       : "<<items.size()<<"\n";
    pause();
}

int main() {
    seedData();
    loadAll();

    while(true) {
        cout<<"\n\n=============================================\n";
        cout<<"       SCHOOL BOOK BILLING APP (C++)\n";
        cout<<"             OFFLINE / NO SERVER\n";
        cout<<"=============================================\n";
        cout<<"1. New Bill\n";
        cout<<"2. Bill History\n";
        cout<<"3. Add School\n";
        cout<<"4. Add Standard\n";
        cout<<"5. Add TextBook\n";
        cout<<"6. Add Notebook/Stationery\n";
        cout<<"7. Reports\n";
        cout<<"8. Save Data\n";
        cout<<"0. Exit\n";
        cout<<"Select: ";

        int choice;
        if(!(cin>>choice)){cin.clear();cin.ignore(10000,'\n');continue;}
        cin.ignore();

        switch(choice) {
            case 1:createBill();break;
            case 2:history();break;
            case 3:addSchool();break;
            case 4:addStandard();break;
            case 5:addItem(true);break;
            case 6:addItem(false);break;
            case 7:reports();break;
            case 8:saveAll();cout<<"Data saved.\n";break;
            case 0:saveAll();return 0;
            default:cout<<"Invalid choice.\n";
        }
    }
}
