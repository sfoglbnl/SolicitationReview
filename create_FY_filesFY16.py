#This code cleans up the full FBO XML file and provides a function that separates the records by Fiscal Year.


from lxml import etree
from datetime import date

tree = etree.parse("/Users/ascodel/Google Drive/SFO Group Files/FEMP EEPP/Solicitation Review/Data/FBO_XML_files/FBOFullXML.xml")
root_full = tree.getroot()
    
 #this creates a new element tree that we can use for each FY

def get_fiscal_year(record): #this function searches through the records to find the fiscal year
    date_str = record[0].text
    date_arr = list(date_str)
    day = int(''.join(date_arr[2:4]))
    month = int(''.join(date_arr[0:2]))
    cal_year =  int(''.join(date_arr[4:8]))
    
    if month<10:
            fy = cal_year
    else: 
            fy = cal_year + 1
    return fy

def make_FYtree(fiscal_year,root_full): #this function finds the fiscal year and if it matches the FY we've defined, appends the new element tree
    root = etree.Element('NOTICE')
    for record in root_full:
        fy = get_fiscal_year(record)
        if str(fy) == fiscal_year:
            root.append(record)
    return root

def write_FY_file(fiscal_year): #this function writes the appended element tree to a new XML file
    root = make_FYtree(fiscal_year,root_full)
    str=etree.tostring(root, pretty_print=True)
    out_file = open(('/Users/ascodel/Google Drive/SFO Group Files/FEMP EEPP/Solicitation Review/Data/FBO_XML_files/FBO_FY'  + fiscal_year + '.xml'),'w')
    out_file.write(str)
    out_file.close()


fiscal_year = "2016"
write_FY_file(fiscal_year)




