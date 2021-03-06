function [derivatives,dc]=setup_derivatives(dns,field,wallMolecule)

% If not set, the molecule at the boudnary is made up of 3 points
if nargin<3
   wallMolecule=3;
end

% Initialize arrays
derivatives.d0=cell(2*dns.nz+1,1);
for IZ=0:dns.nz; iz=dns.nz+1+IZ;
    derivatives.d0{iz}=zeros(dns.ny-field.iy0(iz)+1,dns.ny-field.iy0(iz)+1);
end
derivatives.d1=derivatives.d0; derivatives.drd=derivatives.d0;
dc=zeros(dns.nz+1,4,3); dc4=dc;

% Compute derivatives
for IZ=0:dns.nz; iz=dns.nz+1+IZ;
    M=zeros(3,3); t=zeros(3,1);
    for iY=field.iy0(iz)+1:dns.ny-1
        % define helping indices
        iy=iY+1; jy=iY-field.iy0(iz)+1;
        % d1
        for i=0:2; for j=0:2; M(i+1,j+1)=(field.y(iy-1+j)-field.y(iy))^(2-i); end; end
        t=t*0; t(2)=1; derivatives.d1{iz}(jy,jy-1:jy+1)=(M\t)';
        % d0
        for i=0:2; for j=0:2; M(i+1,j+1)=(3-i)*(field.y(iy-1+j)-field.y(iy))^(2-i); end; end
        t=t*0; for i=0:2; for j=-1:1; t(i+1)=t(i+1)+derivatives.d1{iz}(jy,jy+j)*(field.y(iy+j)-field.y(iy))^(3-i); end; end; derivatives.d0{iz}(jy,jy-1:jy+1)=(M\t)'; 
        % drd
        for i=0:2; for j=0:2; M(i+1,j+1)=(field.y(iy-1+j)-field.y(iy))^(2-i); end; end
        t=t*0; 
        for i=0:1 
            for j=-1:1 
                if i<1; t(i+1)=t(i+1)+derivatives.d0{iz}(jy,jy+j)*(field.y(iy+j)*(2-i)*(1-i)*(field.y(iy+j)-field.y(iy))^(-i)); end
                t(i+1)=t(i+1)+derivatives.d0{iz}(jy,jy+j)*( (2-i)*(field.y(iy+j)-field.y(iy))^(1-i) ); 
            end 
        end; derivatives.drd{iz}(jy,jy-1:jy+1)=(M\t);
    end
    
    % position at which a mode iz appears
    s=((dns.ny-field.iy0(iz)+1)>=wallMolecule)*(wallMolecule-3)+3; S=s-1;
    M=zeros(s,s); t=zeros(s,1);
    iY=field.iy0(iz); iy=iY+1; jy=iy-field.iy0(iz);
    for i=0:S; for j=0:S; M(i+1,j+1)=(field.y(iy+j)-field.y(iy))^(S-i); end; end
    t=t*0; t(S)=1; derivatives.d1{iz}(jy,jy:jy+S)=M\t; derivatives.d0{iz}(jy,jy)=1;
    for i=0:S; for j=0:S; M(i+1,j+1)=(field.y(iy+j)-field.y(iy))^(S-i); end; end
    t=t*0; t(S)=1; t(S-1)=2*field.y(iy); derivatives.drd{iz}(jy,jy:jy+S)=M\t; 
    
    % wall
    s=((dns.ny-field.iy0(iz)+1)>=wallMolecule)*(wallMolecule-3)+3; S=s-1;
    iY=dns.ny; iy=iY+1; jy=iY-field.iy0(iz)+1;
    for i=0:S; for j=0:S; M(i+1,j+1)=(field.y(iy-S+j)-field.y(iy))^(S-i); end; end
    t=t*0; t(S)=1; derivatives.d1{iz}(jy,jy-S:jy)=M\t; derivatives.d0{iz}(jy,jy)=1;
    for i=0:S; for j=0:S; M(i+1,j+1)=(field.y(iy-S+j)-field.y(iy))^(S-i); end; end
    t=t*0; t(S)=1; t(S-1)=2*field.y(iy); derivatives.drd{iz}(jy,jy-S:jy)=M\t; 
end

% copy difference coefficients for 'negative' iz modes
for m=1:dns.nz
    derivatives.d0{dns.nz+1-m}=derivatives.d0{dns.nz+1+m}; 
    derivatives.d1{dns.nz+1-m}=derivatives.d1{dns.nz+1+m};
    derivatives.drd{dns.nz+1-m}=derivatives.drd{dns.nz+1+m};
end

M=zeros(3,3); t=zeros(3,1);
% regularity conditions
for m=0:1 
    for IZ=m:dns.nz; iz=IZ+1;
      for i=0:1; for j=0:2; M(i+2,j+1)=field.y(j+field.iy0(iz+dns.nz)+1)^(IZ-m+2*i); end; end
      t=t*0; t(1)=1; M(1,:)=[1;0;0]; dc4(iz,m+1,1:3)=M\t; 
      %dc2(iz+1,m+1,1)=1; dc2(iz+1,m+1,2)=-(field.y(field.iy0(m+1)+1)/field.y(field.iy0(m+1)+1+1))^(iz-m); dc2(iz+1,m+1,3)=0;
    end
end
%dc2(1,2,:)=dc2(3,2,:); dc4(1,2,:)=dc4(3,2,:);
dc4(1,2)=dc4(3,2);
dc(:,1,:)=dc4(:,1,:);  dc(:,2,:)=dc4(:,1,:);
dc(:,3,:)=dc4(:,2,:);  dc(:,4,:)=dc4(:,2,:);


