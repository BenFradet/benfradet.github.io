---
layout: post
title: Why you should use vim
categories:
    - vim
image: vim.png
---

While there is a somewhat steep learning curve to use vim at its full potential
I think it is one of the best, if not the best, text editor out there. What 
makes it really awesome are the plugins and the fact that you can develop your 
own. Just to give you an idea, I use vim to write/code pretty much everything: 
sql queries, webapps, this blog, scala, etc.
 

In this post, I am going to list the plugins I use to maximize my productivity 
and go over my .vimrc to give you a few ideas if you are planning on using vim.

###Plugin manager
The first thing you need is a plugin manager, there are two main alternatives:

*  [Vundle](https://github.com/gmarik/Vundle.vim)
*  [pathogen](https://github.com/tpope/vim-pathogen/)

As the name implies you will use this plugin to install and manage other plugin.
Personally, I used to use pathogen but recently switched to Vundle and I
could not be happier.

In my .vimrc:
{% highlight c %}
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

"your other plugins

call vundle#end()
filetype plugin indent on
{% endhighlight %}

###Plugins
*  [neocomplcache](https://github.com/Shougo/neocomplcache.vim)

Ultimate tool to increase your productivity, neocomplcache helps you avoid
typing the same word twice, it caches everything you type and
suggests it when you type it again.

This list is by no means exhaustive but should give you a good headstart.

