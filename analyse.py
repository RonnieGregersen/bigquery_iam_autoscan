import pandas as pd


print("Checking dataset permissions...")

dfIS_EU = pd.read_json("informationSchemas/jobsByUserEU.json")

useraccess = pd.read_csv("result.csv")

DatasetAccess = useraccess[useraccess['TABLE'] == " DATASET LEVEL"]
TableAccess = useraccess[useraccess['TABLE'] != " DATASET LEVEL"]


uniques=pd.DataFrame(DatasetAccess["USER"].unique())


isActive = pd.Series(uniques[0].isin(dfIS_EU.user_email).values.astype(int), uniques[0].values)
# isActive=isActive.sort_values(ascending=True)
isActive = isActive.loc[lambda x : x == 0]
isActive=isActive.to_frame()
isActive.to_csv('inactiveDatasetAccounts.csv')





print("Checking table permissions...")
userlst = []

for userlist in TableAccess.USER:
    current = userlist
    current = current.replace('["', '')
    current = current.replace('"]', '')
    current = current.replace('"', '')
    current = current.replace('user:', '')
    convert = list(current.split(" "))
    for account in convert:
        userlst.append(account)

userlst = pd.DataFrame(userlst, columns =['account'])
uniques = pd.DataFrame(userlst["account"].unique())
isActive = pd.Series(uniques[0].isin(dfIS_EU.user_email).values.astype(int), uniques[0].values)
isActive = isActive.loc[lambda x : x == 0]
isActive = isActive.to_frame()
isActive.to_csv('inactiveTableAccounts.csv')
