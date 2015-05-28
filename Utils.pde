String saveFilename()
{
  String sf = "cdm_" + year() + "-" + month() + "-" + day() + "_" + hour() + "." + minute() + "." + second() + ".png";
  return sf;
}
