"""
Mena Kiser
09/20/2025
Read tables from Wayback machine files and store them in individual excel files
with one sheet per table
"""

import os
import pandas as pd
from bs4 import BeautifulSoup
from pathlib import Path

user_folder = "/Users/jimenakiser/Desktop/287g/"

def extract_all_287g_tables(base_dir, output_dir, typefile ):
    os.makedirs(output_dir, exist_ok=True)

    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file == f"{typefile}":
                full_path = os.path.join(root, file)

                # Extract {datename} from path like: /ice/wayback/{datename}/...
                parts = Path(full_path).parts
                try:
                    datename_index = parts.index("wayback") + 3
                    datename = parts[datename_index]
                except (ValueError, IndexError):
                    print(f"Skipping {full_path} (could not extract datename)")
                    continue

                # Output path: /ice/tables/{datename}_287g.xlsx
                save_path = os.path.join(output_dir, f"{datename}.xlsx")
                save_tables_to_excel(full_path, save_path, datename)

def save_tables_to_excel(html_file_path, output_excel_path, datename):
    with open(html_file_path, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'html.parser')

    tables = soup.find_all('table')

    if not tables:
        print(f"No tables found in {html_file_path}")
        return  # just skip saving, continue to next file

    total_tables = len(tables)

    with pd.ExcelWriter(output_excel_path, engine='xlsxwriter') as writer:
        for i, table in enumerate(tables):
            try:
                # --- extract paragraphs before table ---
                prev_paras = []
                prev = table.find_previous_siblings()
                for tag in prev:
                    if tag.name == "p":
                        prev_paras.append(tag.get_text(strip=True))
                        if len(prev_paras) == 2:
                            break
                prev_paras = prev_paras[::-1]

                # --- parse table into DataFrame ---
                df = pd.read_html(str(table))[0]

                # --- extract links manually ---
                link_cols = []
                for row_idx, row in enumerate(table.find_all("tr")):
                    row_links = []
                    for cell in row.find_all(["td", "th"]):
                        for a in cell.find_all("a", href=True):
                            row_links.append(a["href"])
                    link_cols.append(row_links)

                max_links = max((len(x) for x in link_cols), default=0)
                for k in range(max_links):
                    df[f"link{k+1}"] = [
                        links[k] if k < len(links) else None
                        for links in link_cols[1:]  # skip header row
                    ]

                # Add metadata columns
                df["datename"] = datename
                df["table_order"] = f"{i+1}/{total_tables}"

                sheet_name = f"Table{i+1}"

                # Write table starting after 2 rows
                df.to_excel(writer, sheet_name=sheet_name, index=False, startrow=2)

                # Write paragraphs above
                worksheet = writer.sheets[sheet_name]
                for j, para in enumerate(prev_paras):
                    worksheet.write(j, 0, para)

            except Exception as e:
                print(f"Failed to parse a table in {html_file_path}: {e}")

    print(f"Saved {len(tables)} tables to {output_excel_path}")




# Run the function Option + Shift + E
#news_factsheets 2011-2014, 2 tables stored at most
news_factsheets_data = f"{user_folder}/data/raw/wayback/news_factsheets"
news_factsheets_out = f"{user_folder}/data/int/wayback/news_factsheets"
extract_all_287g_tables(news_factsheets_data, news_factsheets_out, "287g.htm")

#factsheets 2015-2017, 2 tables stored at most
factsheets_data = f"{user_folder}/data/raw/wayback/factsheets"
factsheets_out = f"{user_folder}/data/int/wayback/factsheets"
extract_all_287g_tables(factsheets_data, factsheets_out,  "287g")

#icegov 2017-2021
icegov_data = f"{user_folder}/data/raw/wayback/icegov"
icegov_out = f"{user_folder}/data/int/wayback/icegov"
extract_all_287g_tables(icegov_data, icegov_out, "index.html")

#idarrests 2021-2025
idarrests_data = f"{user_folder}/data/raw/wayback/idarrests"
idarrests_out = f"{user_folder}/data/int/wayback/idarrests"
extract_all_287g_tables(idarrests_data, idarrests_out, "287g")