# How to Push an Image to a Private Repository

## Prerequisites

Lets assume the image is called myApp and the remote repository
is called blade1.se.internal:5000

## Process

Tag a local repository for remote publishing
# docker tag MyApp blade1.se.internal:5000/MyApp

Push the image to remote
# docker push blade1.se.internal:5000/MyApp

