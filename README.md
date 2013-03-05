git-asset is yet another implementation of git-media
====================================================

### What's the difference between git-asset and git-media?

mostly same approach.
git-asset pushes assets when executing `git-add`. basically, you don't care about pushing files.
Transport class has `exists` API. so we can check existence of file before pushing it.
And, git-asset provides usefull command for `git filter-branch`. Yay

Sounds good? :octocat: but still EXPERIMENTAL!

Basic Usage
-----------

````bash
# export path for git-asset
GIT_ASSET_HOME=/path/to/git-asset
export PATH=$PATH:$GIT_ASSET_HOME/bin

# NB: THIS PROCESS CHANGES YOUR COMMIT HISTORY. PLEASE TEST WITH BACKUP REPOSITORY.
# go to your repo. and clean repository at first. this process is in proportion to commit count.
cd path/to/repo
git filter-branch --tree-filter 'git asset clean-repository' --prune-empty -f -- --all

# remove filter-branch backup and execute gc
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now

# now, all image / resource files are move to

````

Commands
--------

````bash
git asset sync
# activate filter and sync (download files from specified source and smudge it. don't do this in dirty working tree)

git asset activate
# activate filter

git asset deactivate
# deactivate filter and checkout files. (don't do this in dirty working tree)
````


Supported Transports
--------------------

:local transport:

````
[git-asset.transport]
    type = local

[git-asset.transport.local]
    path = /var/git-asset/<reponame>/
````

:scp transport:

````
[git-asset.transport]
    type = scp

[git-asset.transport.scp]
    user = someuser
    host = remoteserver.com
    path = /opt/media
    port = 22
# you can also specify scp options with opts key.
    opts = -l 8000
````

:s3 transport:

````
[git-asset.transport]
    type = s3

[git-asset.transport.s3]
    key    = S3KEY
    secret = S3SECRET
    bucket = BucketName
    endpoint = s3-ap-northeast-1.amazonaws.com (tokyo region)
````


References
----------

* git-media: https://github.com/schacon/git-media
* 6.4 Git Tools - Rewriting History: (from Pro git book): http://git-scm.com/book/ch6-4.html

License
-------

Copyright (c) <2013> Shuhei Tanuma<chobieee@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.