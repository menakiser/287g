from PIL import Image
import pytesseract
import os
import pandas as pd

def extract_text_from_images_to_excel(image_paths, output_excel_path):
    # Dictionary to store extracted text with corresponding image name
    extracted_text = {}

    for image_path in image_paths:
        # Load image
        image = Image.open(image_path)

        # Extract text using Tesseract OCR
        text = pytesseract.image_to_string(image)

        # Use the filename (without extension) as the sheet name
        sheet_name = os.path.splitext(os.path.basename(image_path))[0]
        extracted_text[sheet_name] = text
        print(f'Text extracted from: {image_path}')

    # Write each extracted text to a separate sheet in Excel
    with pd.ExcelWriter(output_excel_path, engine='xlsxwriter') as writer:
        for sheet_name, text in extracted_text.items():
            # Convert text to DataFrame for saving to Excel
            df = pd.DataFrame([text.split('\n')]).T
            df.columns = ['Extracted Text']
            df.to_excel(writer, sheet_name=sheet_name[:31], index=False)  # Excel sheet name max length = 31

    print(f'Text from all images saved to: {output_excel_path}')


if __name__ == "__main__":
    image_file_path = ["/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice_foia/ddor2017_10.jpg"]
    output_excel_path = f"/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/secure_communities/ice_foia/ddor2017.xlsx"
    extract_text_from_images_to_excel(image_file_path, output_excel_path)