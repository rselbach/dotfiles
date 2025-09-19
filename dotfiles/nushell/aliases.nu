# Shell command aliases

# Navigation and listing
export alias l = ls --all
export alias c = clear
export alias ll = ls -l
export alias lt = eza --tree --level=2 --long --icons --git

# Editors
export alias v = nvim

# System management
export alias hms = /nix/store/6kc5srg83nkyg21am089xx7pvq44kn2c-home-manager/bin/home-manager switch
export alias as = aerospace

# Git aliases
export alias gc = git commit -m
export alias gca = git commit -a -m
export alias gp = git push origin HEAD
export alias gpu = git pull origin
export alias gst = git status
export alias glog = git log --graph --topo-order --pretty='%w(100,0,6)%C(yellow)%h%C(bold)%C(black)%d %C(cyan)%ar %C(green)%an%n%C(bold)%C(white)%s %N' --abbrev-commit
export alias gdiff = git diff
export alias gco = git checkout
export alias gb = git branch
export alias gba = git branch -a
export alias gadd = git add
export alias ga = git add -p
export alias gcoall = git checkout -- .
export alias gr = git remote
export alias gre = git reset

# Kubernetes aliases
export alias k = kubectl
export alias ka = kubectl apply -f
export alias kg = kubectl get
export alias kd = kubectl describe
export alias kdel = kubectl delete
export alias kl = kubectl logs
export alias kgpo = kubectl get pod
export alias kgd = kubectl get deployments
export alias kc = kubectx
export alias kns = kubens
export alias kl = kubectl logs -f
export alias ke = kubectl exec -it

# Muscle memory overrides
export alias 'ps -ef' = ps
