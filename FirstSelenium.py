"""Return the pathname of the KOS root directory."""


def run_calculation():
    """ my docstring """
    from selenium import webdriver
    from selenium.webdriver.common.keys import Keys
    from selenium.webdriver.support.ui import Select


    driver = webdriver.Chrome()

    driver.get("http://dium.dbcargo.com/dium/")
    driver.get("http://dium.dbcargo.com/dium/profisuche.do?initContext=1&style=stinnes")

    #elem = driver.find_element_by_name("v_lnd_nr")
    select = Select(driver.find_element_by_name("v_lnd_nr"))
    select.select_by_value("80")

    elem = driver.find_element_by_name("v_gvi_attrib")
    elem.send_keys("112318")

    select = Select(driver.find_element_by_name("e_lnd_nr"))
    select.select_by_value("80")

    elem = driver.find_element_by_name("e_gvi_attrib")
    elem.send_keys("010801")

    elem.send_keys(Keys.RETURN)

    table_id = driver.find_element_by_class_name("rtfTable")
    row = table_id.find_elements_by_tag_name("tr")[2] # get all of the rows in the table

    #Get the columns (all the column 2)
    col = row.find_elements_by_tag_name("td")[6] #note: index start from 0, 1 is col 2

    print("Kilometer:")
    print(col.text) #prints text from the element

    #assert "No results found." not in driver.page_source

    driver.close()


run_calculation()
