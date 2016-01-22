unit class X::LWP::Simple::Response is Exception;

has Str $.status is rw;
has Hash $.headers is rw;
has Str $.content is rw;

method Str() {
    return ~self.status;
}

method gist() {
    return self.Str;
}
