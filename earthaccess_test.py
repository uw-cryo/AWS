import earthaccess
import xarray as xr

# will use EARTHDATA_TOKEN in environment variables
auth = earthaccess.login(strategy="environment")

# Quikstart Example:
# https://earthaccess.readthedocs.io/en/stable/quick-start/

results = earthaccess.search_data(
    short_name='ATL06',
    bounding_box=(-10, 20, 10, 50),
    temporal=("1999-02", "2019-03"),
    cloud_hosted=True,
    count=1
)
print(results)

fileobjects = earthaccess.open(results)
ds = xr.open_dataset(fileobjects[0])

files = earthaccess.download(results, "/tmp/local_folder")


# S3 Access example

# import h5coro

# # https://earthaccess.readthedocs.io/en/stable/user_guide/authenticate/#using-earthaccess-to-get-s3-credentials
# auth = earthaccess.login()
# s3_credentials = auth.get_s3_credentials(daac="NSIDC")

# s3url_atl23 = 'nsidc-cumulus-prod-protected/ATLAS/ATL23/001/2023/03/' \
#                 '01/ATL23_20230401000000_10761801_001_01.h5'

# ds = xr.open_dataset(s3url_atl23, engine='h5coro',
#                      group='/mid_latitude/beam_1',
#                      credentials=s3_credentials)
