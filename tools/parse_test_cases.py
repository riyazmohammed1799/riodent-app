import zipfile
import xml.etree.ElementTree as ET
import json
import os

EXCEL_PATH = r"C:\Users\riyaz\Downloads\Riodent_MVP_QA_Test_Cases_v2 (1).xlsx"
OUTPUT_JSON = r"c:\Users\riyaz\riodent_claude\qa_test_cases_v2_extracted.json"

def parse_excel(path):
    with zipfile.ZipFile(path, 'r') as z:
        # 1. Read shared strings
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            ss_root = ET.fromstring(z.read('xl/sharedStrings.xml'))
            ns = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
            for si in ss_root.findall('m:si', ns):
                # Concatenate all text in 't' elements
                text_pieces = [t.text for t in si.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t') if t.text]
                shared_strings.append("".join(text_pieces))

        # 2. Read workbook to map sheet name to rId and file
        wb_root = ET.fromstring(z.read('xl/workbook.xml'))
        ns_wb = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
                 'r': 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'}
        
        # Read relationships
        rel_root = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
        ns_rel = {'r': 'http://schemas.openxmlformats.org/package/2006/relationships'}
        rel_map = {}
        for rel in rel_root.findall('r:Relationship', ns_rel):
            rel_map[rel.attrib['Id']] = rel.attrib['Target']

        sheets_info = []
        for s in wb_root.findall('m:sheets/m:sheet', ns_wb):
            sheet_name = s.attrib['name']
            r_id = s.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']
            target = rel_map[r_id]
            # normalize target path
            if not target.startswith('xl/'):
                target = 'xl/' + target.lstrip('/')
            sheets_info.append((sheet_name, target))

        print(f"Discovered {len(sheets_info)} sheets:")
        for name, target in sheets_info:
            print(f" - Sheet: '{name}' -> {target}")

        all_sheets_data = {}

        # 3. Parse each sheet
        for sheet_name, target in sheets_info:
            if target not in z.namelist():
                print(f"Warning: {target} not in zip archive.")
                continue
            
            sheet_root = ET.fromstring(z.read(target))
            ns_s = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
            
            rows_data = []
            rows = sheet_root.findall('m:sheetData/m:row', ns_s)
            
            for row in rows:
                row_idx = row.attrib.get('r')
                row_cells = {}
                for cell in row.findall('m:c', ns_s):
                    cell_ref = cell.attrib.get('r', '') # e.g. A1, B2
                    # strip row numbers from cell_ref to get column letters
                    col_letters = ''.join([c for c in cell_ref if c.isalpha()])
                    cell_type = cell.attrib.get('t', '')
                    v_elem = cell.find('m:v', ns_s)
                    val = ""
                    if v_elem is not None and v_elem.text is not None:
                        val = v_elem.text
                        if cell_type == 's':
                            idx = int(val)
                            val = shared_strings[idx] if idx < len(shared_strings) else val
                    elif cell_type == 'inlineStr':
                        t_elem = cell.find('m:is/m:t', ns_s)
                        if t_elem is not None and t_elem.text:
                            val = t_elem.text

                    row_cells[col_letters] = val
                
                rows_data.append(row_cells)

            all_sheets_data[sheet_name] = rows_data
            print(f"Sheet '{sheet_name}': {len(rows_data)} rows parsed.")

        # Save to JSON
        with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
            json.dump(all_sheets_data, f, indent=2, ensure_ascii=False)
        print(f"Saved complete extracted data to {OUTPUT_JSON}")

if __name__ == "__main__":
    parse_excel(EXCEL_PATH)
