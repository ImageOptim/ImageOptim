<?php

$bundleName = "ImageOptim";
$baseURL = dirname(readKey('SUFeedURL'));
$minOSVersion = readKey('LSMinimumSystemVersion');
$exactVersion = readKey('CFBundleVersion');
$niceVersion = readKey('CFBundleShortVersionString');
if (!$niceVersion) $niceVersion = $exactVersion;

$download_url = "$baseURL/$bundleName$exactVersion.tar.bz2";
$archivepath = isset($argv[1]) ? $argv[1] : "build/Release/$bundleName.tar.bz2";
$pempath = getenv("HOME")."/.ssh/dsa_priv_imageoptim.pem";

$appcastpath = rawurldecode(basename(readKey('SUFeedURL')));

const SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle";

if (!file_exists($archivepath)) throw new Exception("Can't find $archivepath");

$feed = new DOMDocument;
$feed->load($appcastpath);

$xp = new DOMXPath($feed);
$xp->registerNamespace("sparkle",SPARKLE_NS);

$item = $xp->query("//item[enclosure/@sparkle:version='$exactVersion']")->item(0);

if (!$item)
{
    $item = getElement($feed->getElementsByTagName('channel')->item(0),"item");
    newline($item);
}

setText(getElement($item, "title"), "Version $niceVersion");
setText(getElement($item, "pubDate"), date(DATE_RSS));
setText(getElement($item, "sparkle:minimumSystemVersion", SPARKLE_NS), $minOSVersion);
getElement($item, "description");

$enc = getElement($item, "enclosure");
$enc->setAttributeNS(SPARKLE_NS, "sparkle:version", $exactVersion);
$enc->setAttribute("url", $download_url);
$enc->setAttribute("length", filesize($archivepath));
$enc->setAttributeNS(SPARKLE_NS, "sparkle:dsaSignature", signUpdate($archivepath, $pempath));


file_put_contents($appcastpath, $feed->saveXML());


function readKey($name)
{
    $plistpath = realpath('Info.plist');
    $domain = preg_replace('/\.plist$/','',$plistpath);

    return system("defaults read ".escapeshellarg($domain)." ".escapeshellarg($name));
}

function getElement(DOMElement $parent, $tagname, $ns = NULL)
{
    if ($ns !== NULL) $el = $parent->getElementsByTagNameNS($ns, preg_replace('/^.*:/','',$tagname))->item(0);
    else $el = $parent->getElementsByTagName($tagname)->item(0);

    if (!$el)
    {
        $el = $parent->ownerDocument->createElementNS($ns, $tagname);
        $parent->appendChild($el);
        newline($parent);
    }

    return $el;
}


function newline(DOMElement $parent)
{
    $parent->appendChild($parent->ownerDocument->createTextNode("\n"));
}

function setText(DOMElement $el, $textcontent)
{
    while($el->firstChild) $el->removeChild($el->firstChild);

    if (strlen($textcontent))
    {
        $el->appendChild($el->ownerDocument->createTextNode($textcontent));
    }
}

function signUpdate($archivepath, $pempath)
{
    return system("ruby sign_update.rb ".escapeshellarg($archivepath)." ".escapeshellarg($pempath));
}
