loadGearList <- function(url){
  print("Loading gear list ...")
  x <- data.table(read.xlsx(url, sheet = "formatted"))
  x[,Group:=tolower(Group)]
  setnames(x, old = c("Code","Group"), new = c("gear_code", "gear_group"))
  if(any(duplicated(x$gear_code))){
    x<-x[!duplicated(x$gear_code)]
    print("Warning! Duplicated gear codes were found and were removed.")
  }
  
  return(x[,.(gear_code,gear_group)])
}
