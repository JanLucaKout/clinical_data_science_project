# ==============================================================================
# Imports
import os
from dotenv import load_dotenv
from google import genai
import pandas as pd
import json
from datetime import datetime

# ==============================================================================
# API Key and Model Handling
api_key_file_path = 'api_keys.env'
load_dotenv(api_key_file_path)
api_key = os.environ.get("GEMINI_API_KEY")
MODEL_NAME = 'gemini-3-flash-preview'
client = genai.Client(api_key=api_key)

# ==============================================================================
# Schema Definition
CLINICAL_SCHEMA = {
    'STUDYID' : 'Study Identifier',
    'USUBJID' : 'Unique Subject Identifier',
    'SUBJID' : 'Subject Identifier',
    'SITEID' : 'Study Site Identifier',
    'COUNTRY' : 'Country',
    'DOMAIN' : 'Domain Abbreviation, AE means Adverse Events',
    'RFSTDTC' : 'Subject Reference Start Date/Time',
    'RFENDTC' : 'Subject Reference End Date/Time',
    'RFXSTDTC' : 'Date/Time of First Study Treatment',
    'RFXENDTC' : 'Date/Time of Last Study Treatment',
    'RFPENDTC' : 'Date/Time of End Participation',
    'SCRFDT' : 'Screen Failure Date',
    'FRVDT' : 'Final Retrieval Visit Date',
    'DTHDTC' : 'Date/Time of Death',
    'DTHADY' : 'Relative Day of Death',
    'DTHFL' : 'Subject Death Flag',
    'LDDTHELD' : 'Elapsed Days from Last Dose to Death',
    'LDDTHGR1' : 'Last Dose to Death - Days Elapsed Grp 1',
    'DTH30FL' : 'Death Within 30 Days of Last Trt Flag',
    'DTHA30FL' : 'Death After 30 Days from Last Trt Flag',
    'DTHDOM' : 'Domain for Date of Death Collection',
    'DTHB30FL' : 'Death Within 30 Days of First Trt Flag',
    'REGION1' : 'Geographic Region 1',
    'DMDTC' : 'Date/Time of Collection',
    'DMDY' : 'Study Day of Collection',
    'AGE' : 'Age',
    'AGEU' : 'Age Units (Usually Years)',
    'AGEGR1' : 'Pooled Age Group 1',
    'SEX' : 'Sex, Gender',
    'RACE' : 'Race',
    'RACEGR1' : 'Pooled Race Group 1',
    'ETHNIC' : 'Ethnicity',
    'SAFFL' : 'Safety Population Flag',
    'ARM' : 'Description of Planned Arm',
    'ARMCD' : 'Planned Arm Code',
    'ACTARM' : 'Description of Actual Arm',
    'ACTARMCD' : 'Actual Arm Code',
    'TRT01P' : 'Planned Treatment for Period 01',
    'TRT01A' : 'Actual Treatment for Period 01',
    'TRTSDT' : 'Date of First Exposure to Treatment',
    'TRTSDTM' : 'Datetime of First Exposure to Treatment',
    'TRTSTMF' : 'Time of First Exposure Imputation Flag',
    'TRTEDT' : 'Date of Last Exposure to Treatment',
    'TRTEDTM' : 'Datetime of Last Exposure to Treatment',
    'TRTETMF' : 'Time of Last Exposure Imputation Flag',
    'EOSSTT' : 'End of Study Status (Completed/Discontinued)',
    'EOSDT' : 'End of Study Date',
    'RFICDTC' : 'Date/Time of Informed Consent',
    'RANDDT' : 'Date of Randomization',
    'LSTALVDT' : 'Date Last Known Alive',
    'TRTDURD' : 'Total Treatment Duration in Days',
    'DTHDT' : 'Date of Death',
    'DTHDTF' : 'Date of Death Imputation Flag',
    'DTHCAUS' : 'Cause of Death',
    'DTHCGR1' : 'Cause of Death Reason 1',
    'AESEQ' : 'Sequence Number',
    'AETERM' : 'Adverse Event Preferred Term (e.g., Headache, Nausea, Fatigue)',
    'AEDECOD' : 'Dictionary-Derived Term',
    'AEBODSYS' : 'Body System or Organ Class',
    'AEBDSYCD' : 'Body System or Organ Class Code',
    'AELLT' : 'Lowest Level Term',
    'AELLTCD' : 'Lowest Level Term Code',
    'AEPTCD' : 'Preferred Term Code',
    'AEHLT' : 'High Level Term',
    'AEHLTCD' : 'High Level Term Code',
    'AEHLGT' : 'High Level Group Term',
    'AEHLGTCD' : 'High Level Group Term Code',
    'AESOC' : 'Primary System Organ Class or body system (e.g., Cardiac, Skin, Nervous system)',
    'AESOCCD' : 'Primary System Organ Class Code',
    'AESTDTC' : 'Start Date/Time of Adverse Event',
    'ASTDT' : 'Analysis Start Date',
    'ASTDTM' : 'Analysis Start Date/Time',
    'ASTDTF' : 'Analysis Start Date Imputation Flag',
    'ASTTMF' : 'Analysis Start Time Imputation Flag',
    'AEENDTC' : 'End Date/Time of Adverse Event',
    'AENDT' : 'Analysis End Date',
    'AENDTM' : 'Analysis End Date/Time',
    'AENDTF' : 'Analysis End Date Imputation Flag',
    'AENTMF' : 'Analysis End Time Imputation Flag',
    'ASTDY' : 'Analysis Start Relative Day',
    'AESTDY' : 'Study Day of Start of Adverse Event as a Integer',
    'AENDY' : 'Analysis End Relative Day',
    'AEENDY' : 'Study Day of End of Adverse Event as a Integer',
    'ADURN' : 'Analysis Duration (N)',
    'ADURU' : 'Analysis Duration Units',
    'TRTEMFL' : 'Treatment Emergent Analysis Flag',
    'AOCCIFL' : '1st Max Sev./Int. Occurrence Flag',
    'AESER' : 'Serious Adverse Event Flag (Y/N)',
    'AESDTH' : 'Results in Death',
    'AESLIFE' : 'Is Life Threatening',
    'AESHOSP' : 'Requires or Prolongs Hospitalization',
    'AESDISAB' : 'Persist or Significant Disability/Incapacity',
    'AESCONG' : 'Congential Anomaly or Birth Defect',
    'AESEV' : 'Severity or Intensity of the AE. Values: MILD, MODERATE, SEVERE',
    'ASEV' : 'Analysis Severity/Intensity',
    'ASEVN' : 'Analysis Severity/Intensity (N)',
    'AEREL' : 'Causality',
    'AREL' : 'Analysis Causality',
    'AEACN' : 'Action Taken with Study Treatment',
    'AESPID' : 'Sponsor-Defined Identifier',
    'AEOUT' : 'Outcome of Adverse Event',
    'AESCAN' : 'Involves Cancer Yes(Y) or No(N)',
    'AESOD' : 'Occurred with Overdose Yes(Y) or No(N)',
    'AEDTC' : 'Date/Time of Collection',
    'LDOSEDTM' : 'End Date/Time of Last Dose',
    'DOSEON' : 'Treatment Dose',
    'DOSEU' : 'Treatment Dose Unit'
}

# ==============================================================================
# GenAI Agent
class ClinicalTrialDataAgent:
    def __init__(self, csv_path):
        self.df = pd.read_csv(csv_path)
        self.audit_log = []  # Container for the JSON documentation

    def parse_question(self, question):
        schema_text = json.dumps(CLINICAL_SCHEMA, indent=2)

        prompt = f"""
        You are a clinical data assistant. 
        Schema: {schema_text}

        Translate the user's question into a JSON object with:
        1. 'target_column': The dictionary key to filter.
        2. 'filter_value': The value to search for.

        Question: "{question}"
        Return ONLY the JSON.
        """

        response = client.models.generate_content(
            model=MODEL_NAME,
            contents=prompt,
            config={'response_mime_type': 'application/json'}
        )
        return json.loads(response.text)

    # Filter the dataframe and calculate unique subjects
    def execute_filter(self, structured_json, original_question):
        col = structured_json['target_column']
        val = structured_json['filter_value']

        mask = self.df[col].astype(str).str.contains(val, case=False, na=False)
        subset = self.df[mask]

        unique_ids = subset['USUBJID'].unique().tolist()

        entry = {
            "timestamp": datetime.now().isoformat(),
            "user_question": original_question,
            "llm_logic": structured_json,
            "results": {
                "unique_subject_count": len(unique_ids),
                "subject_ids": unique_ids
            }
        }
        self.audit_log.append(entry)
        return entry

    def save_documentation(self, filename="query_results.json"):
        with open(filename, 'w') as f:
            json.dump(self.audit_log, f, indent=4)
        print(f"\nDocumentation was saved to {filename}")


# ==============================================================================
# Demonstration Script
if __name__ == "__main__":
    agent = ClinicalTrialDataAgent("adae.csv")

    queries = [
        "Give me the subjects who had Adverse events of Moderate severity.",
        "Which patients reported a Headache?",
        "Identify subjects with Cardiac related issues."
    ]

    print(f"--- Roche GenAI Agent: Processing {len(queries)} queries ---")

    for q in queries:
        print(f"\nProcessing: {q}")
        intent = agent.parse_question(q)
        result = agent.execute_filter(intent, q)

        print(f"-> Logic: Filter {intent['target_column']} for '{intent['filter_value']}'")
        print(f"-> Found {result['results']['unique_subject_count']} unique subjects.")

    agent.save_documentation()
