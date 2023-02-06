read_shape_zip <- function(path,layer){
    cur_tempfile <- tempfile()
    out_directory <- tempfile()
    unzip(path, exdir = out_directory)
    st_read(dsn = out_directory,layer) 
}