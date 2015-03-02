function Flow {
    param(
        [Parameter(Position=0, Mandatory=$true)][string]$Category,
        [Parameter(Position=1)][string]$NameOrAction = "",
        [Parameter(Position=2)][string]$Action = "",
        [Parameter(Position=3)][string]$Arg1 = ""
    )

    $DefaultBranch = "master"
    $DevelopBranch = "dev"
    $FeatureBranchPrefix = "f-"
    $HotfixBranchPrefix = "h-"
	$Name = $NameOrAction;

    function category-develop {
        if ($Action -eq "start") {
            git checkout $DefaultBranch -b $DevelopBranch

        } elseif ($Action -eq "pull") {
            git checkout $DevelopBranch
            git rebase $DefaultBranch

        } elseif ($Action -eq "push") {
            git checkout $DefaultBranch
			$published = branch-published $DevelopBranch;
	        git merge $DevelopBranch --no-ff -m "[merge] push $DevelopBranch"
			git checkout $DevelopBranch

        } elseif ($Action -eq "finish") {
            git checkout $DefaultBranch
            git merge $DevelopBranch --no-ff -m "[merge] finished $DevelopBranch"
            if ($?) {
                git branch -d $DevelopBranch
            }

        } elseif ($Action -eq "squash") {
            git checkout $DevelopBranch
            $CommonAncestor = git merge-base $DevelopBranch $DefaultBranch 
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending") {
            $Range = "$DefaultBranch..$DevelopBranch"
            git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range

        } elseif ($Action -eq "") {
            git checkout $DevelopBranch

        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-hotfix {
        $HotfixBranchName = "$HotfixBranchPrefix$Name";

		function category-hotfix-push([string]$MergeMessage) {
            git checkout $DefaultBranch
			git merge $HotfixBranchName --no-ff -m $MergeMessage
            if ($?) {
                git checkout $DevelopBranch
				git merge $HotfixBranchName --no-ff -m $MergeMessage
			}
			git checkout $HotfixBranchName

			#$published = branch-published $DefaultBranch
			
			#if ($published) {
			#	git merge $HotfixBranchName --no-ff -m $MergeMessage
			#} else {
			#	git rebase $HotfixBranchName
			#}

            #if ($?) {
			#	$published = branch-published $DevelopBranch
            #    git checkout $DevelopBranch
			#	if ($published) {
			#		git merge $HotfixBranchName --no-ff -m $MergeMessage
			#	} else {
			#		git rebase $HotfixBranchName
			#	}
            #}

			#git checkout $HotfixBranchName
		}

        if ($Action -eq "start") {
            git checkout $DefaultBranch -b $HotfixBranchName

        } elseif ($Action -eq "pull") {
            git checkout $HotfixBranchName
            git rebase $DefaultBranch

        } elseif ($Action -eq "push") {
			category-hotfix-push "[merge] push $HotfixBranchName";

        } elseif ($Action -eq "finish") {
			category-hotfix-push "[merge] finished $HotfixBranchName";
            git branch -d $HotfixBranchName

        } elseif ($Action -eq "squash") {
            git checkout $HotfixBranchName
            $CommonAncestor = git merge-base $DefaultBranch $HotfixBranchName
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending") {
            $Range = "$DevelopBranch..$HotfixBranchName"
            git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range

        } elseif ($Action -eq "") {
            git checkout $HotfixBranchName

        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-feature {
        $FeatureBranchName = "$FeatureBranchPrefix$Name";
        
        if ($Action -eq "start") {
            git checkout $DevelopBranch -b $FeatureBranchName

        } elseif ($Action -eq "pull") {
            git checkout $FeatureBranchName
            git rebase $DevelopBranch

        } elseif ($Action -eq "push") {
            git checkout $DevelopBranch
	        git merge $FeatureBranchName --no-ff -m "[merge] push $FeatureBranchName"
			git checkout $FeatureBranchName

        } elseif ($Action -eq "finish") {
            git checkout $DevelopBranch
            git merge $FeatureBranchName --no-ff -m "[merge] finished $FeatureBranchName"
            if ($?) {
                git branch -d $FeatureBranchName
            }

        } elseif ($Action -eq "squash") {
            git checkout $FeatureBranchName
            $CommonAncestor = git merge-base $DevelopBranch $FeatureBranchName
            git rebase -i $CommonAncestor

        } elseif ($Action -eq "pending") {
            $Range = "$DevelopBranch..$FeatureBranchName"
            git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range
        
        } elseif ($Action -eq "") {
            git checkout $FeatureBranchName

        } else 
        {
            Write-Host "Invalid action."
        }
    }

    function category-environment {

        if ($Action -eq "pending") {

            $Source = ""            
            if ($Name -eq "hotfix") {
                $Source = $DefaultBranch
            } elseif ($Name -eq "stage") {
                $Source = $DevelopBranch
            } elseif ($Name -eq "dev") {
                $Source = $DefaultBranch
            } elseif ($Name -eq "prod") {
                $Source = $DefaultBranch
            } else {
                Write-Host "Invalid Name."
            }

            if ($Source -ne "") {
                $Range = "$Name..$Source"
                git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative $Range
            }
        
        } elseif ($Action -eq "deploy") {
            if ($Name -eq "hotfix") {
                git checkout hotfix
                git merge $DefaultBranch --ff
                if ($?) {
                    git push
                    git checkout $DefaultBranch
                }

            } elseif ($Name -eq "stage") {
                git checkout stage
                git merge $DevelopBranch --ff
                if ($?) {
                    git push
                    git checkout $DevelopBranch
                }

            } elseif ($Name -eq "prod") {
                $Source = $Arg1
                if ($Source -eq "") {
                    $Source = $DefaultBranch
                }

                git checkout prod
                git merge $Source --ff
                if ($?) {
                    git push
                    git checkout $Source
                }

            } else {
                Write-Host "Invalid name."
            }

        } elseif ($Action -eq "") {
            git checkout $Name
        }       
    }
    
	function branch-published([string]$BranchName) {
		#$Ret = git ls-remote --heads origin $BranchName
		$Range = "origin/$BranchName..$BranchName"
		$Ret = git log --oneline $Range
		$Ret = [string]::IsNullOrEmpty($Ret)
		return $Ret;
	}

    if ($Category -eq "feature" -or $Category -eq "f") { 
        category-feature; 
    } elseif ($Category -eq "develop" -or $Category -eq $DevelopBranch) { 
		$Action = $NameOrAction;
        category-develop; 
    } elseif ($Category -eq "hotfix") { 
        category-hotfix; 
    } elseif ($Category -eq "environment" -or $Category -eq "env") { 
        category-environment; 
    } else {
        Write-Host "Invalid category."
    }
}

Export-ModuleMember -Function @( 'Flow' )

Write-Host "posh-gitflow ready." -ForegroundColor Green

