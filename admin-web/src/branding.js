export const FIXED_BRAND_NAME = "SR EduNova";
export const DEFAULT_INSTITUTE_NAME = "Your Institute Name";

function legacyInstituteName(value) {
  const name = String(value || "").trim();
  const normalized = name.toLowerCase();
  const previousBrandName = ["tech", "jaguar"].join("");

  if (
    !name ||
    normalized === FIXED_BRAND_NAME.toLowerCase() ||
    normalized === previousBrandName
  ) {
    return "";
  }

  return name;
}

export function normalizeAppSettings(data = {}) {
  const instituteName =
    String(data?.instituteName || "").trim() ||
    legacyInstituteName(data?.appName);

  return {
    brandName: FIXED_BRAND_NAME,
    appName: FIXED_BRAND_NAME,
    instituteName: instituteName || DEFAULT_INSTITUTE_NAME,
    logoUrl: data?.logoUrl || "",
  };
}
