# in terminal
# waybackpack http://www.ice.gov/news/library/factsheets/287g.htm -d /Users/jimenakiser/liegroup\ Dropbox/Jimena\ Villanueva\ Kiser/secure_communities/ice/wayback/pre2015 --from-date 2010 --to-date 2014
# waybackpack http://www.ice.gov/news/library/factsheets/287g -d /Users/jimenakiser/liegroup\ Dropbox/Jimena\ Villanueva\ Kiser/secure_communities/ice/wayback/2015-2020 --from-date 2015 --to-date 2020
# https://www.ice.gov/doclib/about/offices/ero/287g/
# waybackpack https://www.ice.gov/identify-and-arrest/287g -d /Users/jimenakiser/liegroup\ Dropbox/Jimena\ Villanueva\ Kiser/secure_communities/ice/wayback/post2020 --from-date 2021 --to-date 2025 --no-clobber
# works best if you try year by year
import os
import pandas as pd
from bs4 import BeautifulSoup
from pathlib import Path

import os
import pandas as pd
from bs4 import BeautifulSoup
from pathlib import Path

def extract_all_287g_tables(base_dir, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file == "287g.htm":
                full_path = os.path.join(root, file)

                # Extract {datename} from path like: /ice/wayback/{datename}/...
                parts = Path(full_path).parts
                try:
                    datename_index = parts.index("wayback") + 1
                    datename = parts[datename_index]
                except (ValueError, IndexError):
                    print(f"Skipping {full_path} (could not extract datename)")
                    continue

                # Output path: /ice/tables/{datename}_287g.xlsx
                save_path = os.path.join(output_dir, f"{datename}_287g.xlsx")
                save_tables_to_excel(full_path, save_path, datename)

def save_tables_to_excel(html_file_path, output_excel_path, datename):
    with open(html_file_path, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'html.parser')

    tables = soup.find_all('table')

    if not tables:
        print(f"No tables found in {html_file_path}")
        return  # just skip saving, continue to next file

    with pd.ExcelWriter(output_excel_path, engine='xlsxwriter') as writer:
        for i, table in enumerate(tables):
            try:
                df = pd.read_html(str(table))[0]
                df["datename"] = datename
                df["table_order"] = i + 1
                sheet_name = f"Table{i+1}"
                df.to_excel(writer, sheet_name=sheet_name, index=False)
            except Exception as e:
                print(f"Failed to parse a table in {html_file_path}: {e}")

    print(f"Saved {len(tables)} tables to {output_excel_path}")


# Run the function
#pre2015
base_pre2015 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/pre2015"  # change if needed
output_pre2015 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/pre2015/tables"   # replace with your desired output directory
#extract_all_287g_tables(base_pre2015, output_pre2015)

#2015-2020
base_2015_2020 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/2015-2020"  # change if needed
output_2015_2020 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/2015-2020/tables"   # replace with your desired output directory
extract_all_287g_tables(base_2015_2020, output_2015_2020)

#post2021
base_post2020 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/post2020"  # change if needed
output_post2020 = "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice/wayback/post2020/tables"   # replace with your desired output directory
extract_all_287g_tables(base_post2020, output_post2020)